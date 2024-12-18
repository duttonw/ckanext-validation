# encoding: utf-8

import logging
import json
import re

import requests
from frictionless import validate, system, Report, Schema, Dialect, Check
from six import string_types

from ckan.model import Session
import ckan.lib.uploader as uploader

import ckantoolkit as tk

from . import utils, settings
from ckanext.validation.validation_status_helper import (ValidationStatusHelper, ValidationJobDoesNotExist,
                                                         ValidationJobAlreadyRunning, StatusTypes)

log = logging.getLogger(__name__)


def run_validation_job(resource):
    vsh = ValidationStatusHelper()
    # handle either a resource dict or just an ID
    # ID is more efficient, as resource dicts can be very large
    if isinstance(resource, string_types):
        log.debug(u'run_validation_job: calling resource_show: %s', resource)
        resource = tk.get_action('resource_show')({'ignore_auth': True}, {'id': resource})

    resource_id = resource.get('id')
    if resource_id:
        log.debug(u'Validating resource: %s', resource_id)
    else:
        log.debug(u'Validating resource dict: %s', resource)
    validation_record = None
    try:
        validation_record = vsh.updateValidationJobStatus(Session, resource_id, StatusTypes.running)
    except ValidationJobAlreadyRunning as e:
        log.error("Won't run enqueued job %s as job is already running or in invalid state: %s", resource['id'], e)
        return
    except ValidationJobDoesNotExist:
        validation_record = vsh.createValidationJob(Session, resource['id'])
        validation_record = vsh.updateValidationJobStatus(
            session=Session, resource_id=resource_id,
            status=StatusTypes.running, validationRecord=validation_record)

    options = utils.get_resource_validation_options(resource)

    dataset = tk.get_action('package_show')(
        {'ignore_auth': True}, {'id': resource['package_id']})

    source = None
    if resource.get(u'url_type') == u'upload':
        upload = uploader.get_resource_uploader(resource)
        if isinstance(upload, uploader.ResourceUpload):
            source = upload.get_path(resource[u'id'])
        else:
            # Upload is not the default implementation (ie it's a cloud storage
            # implementation)
            pass_auth_header = tk.asbool(
                tk.config.get(u'ckanextk.validation.pass_auth_header', True))
            if dataset[u'private'] and pass_auth_header:
                s = requests.Session()
                s.headers.update({
                    u'Authorization': tk.config.get(
                        u'ckanextk.validation.pass_auth_header_value',
                        utils.get_site_user_api_key())
                })

                options[u'http_session'] = s

    if not source:
        source = resource[u'url']

    schema = resource.get(u'schema')
    if schema and isinstance(schema, string_types):
        if schema.startswith('http'):
            r = requests.get(schema)
            schema = r.json()
        else:
            schema = json.loads(schema)

    _format = resource[u'format'].lower()

    report = _validate_table(source, _format=_format, schema=schema, **options)

    # Hide uploaded files
    if isinstance(report, Report):
        report = report.to_dict()

    if 'tasks' in report:
        for table in report['tasks']:
            if table['place'].startswith('/'):
                table['place'] = resource['url']

    if 'warnings' in report:
        for index, warning in enumerate(report['warnings']):
            report['warnings'][index] = re.sub(r'Table ".*"', 'Table', warning)

    if u'valid' in report:
        status = StatusTypes.success if report[u'valid'] else StatusTypes.failure
        validation_record = vsh.updateValidationJobStatus(Session, resource['id'], status, json.dumps(report), None, validation_record)
    else:
        status = StatusTypes.error
        error_payload = {'message': ['Errors validating the data']}
        if 'errors' in report and report['errors']:
            error_payload = {'message': [str(err) for err in report['errors']]}
        validation_record = vsh.updateValidationJobStatus(Session, resource['id'], status, json.dumps(report), error_payload, validation_record)

    # Store result status in resource
    data_dict = {
        'id': resource['id'],
        'validation_status': validation_record.status,
        'validation_timestamp': validation_record.finished.isoformat(),
    }

    if settings.get_update_mode_from_config() == 'sync':
        data_dict['_skip_next_validation'] = True,

    tk.get_action('resource_patch')(
        {'ignore_auth': True,
         'user': tk.get_action('get_site_user')({'ignore_auth': True})['name'],
         '_validation_performed': True},
        data_dict)
    utils.send_validation_report(utils.validation_dictize(validation_record))


def _validate_table(source, _format=u'csv', schema=None, **options):

    # This option is needed to allow Frictionless Framework to validate absolute paths
    frictionless_context = {'trusted': True}
    http_session = options.pop('http_session', None) or requests.Session()

    use_proxy = 'ckan.download_proxy' in tk.config
    if use_proxy:
        proxy = tk.config.get('ckan.download_proxy')
        log.debug(u'Download resource for validation via proxy: %s', proxy)
        http_session.proxies.update({'http': proxy, 'https': proxy})

    frictionless_context['http_session'] = http_session
    resource_schema = Schema.from_descriptor(schema) if schema else None

    # Load the Resource Dialect as described in https://framework.frictionlessdata.io/docs/framework/Dialect.html
    if 'dialect' in options:
        dialect = Dialect.from_descriptor(options['dialect'])
        options['dialect'] = dialect

    # Load the list of checks and its parameters declaratively as in https://framework.frictionlessdata.io/docs/checks/table.html
    if 'checks' in options:
        checklist = [Check.from_descriptor(c) for c in options['checks']]
        options['checks'] = checklist

    with system.use_context(**frictionless_context):
        report = validate(source, format=_format, schema=resource_schema, **options)
        log.debug(u'Validating source: %s', source)

    return report

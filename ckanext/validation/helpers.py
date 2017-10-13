# encoding: utf-8
import json

from ckan.lib.helpers import url_for_static
from ckantoolkit import url_for, _, config, asbool, literal


def get_validation_badge(resource, in_listing=False):

    if in_listing and not asbool(
            config.get('ckanext.validation.show_badges_in_listings', True)):
        return ''

    if not resource.get('validation_status'):
        return ''

    messages = {
        'success': _('Valid data'),
        'failure': _('Invalid data'),
        'error': _('Error during validation'),
        'unknown': _('Data validation unknown'),
    }

    if resource['validation_status'] in ['success', 'failure', 'error']:
        status = resource['validation_status']
    else:
        status = 'unknown'

    validation_url = url_for(
        'validation_read',
        id=resource['package_id'],
        resource_id=resource['id'])

    badge_url = url_for_static(
        '/images/badges/data-{}-flat.svg'.format(status))

    return '''
<a href="{validation_url}" class="validation-badge">
    <img src="{badge_url}" alt="{alt}" title="{title}"/>
</a>'''.format(
        validation_url=validation_url,
        badge_url=badge_url,
        alt=messages[status],
        title=resource.get('validation_timestamp', ''))


def validation_extract_report_from_errors(errors):

    report = None
    for error in errors.keys():
        if error == 'validation':
            report = errors[error][0]
            msg = _('''
Data validation errors found, please check the <a {params}>report</a>.''')
            params = [
                'href="#validation-report"',
                'data-module="modal-dialog"',
                'data-module-div="validation-report-dialog"',
            ]
            new_error = literal(msg.format(params=' '.join(params)))
            errors[error] = [new_error]
            break

    return report, errors


#!/usr/bin/env sh
##
# Create some example content for extension BDD tests.
#
set -e

CKAN_ACTION_URL=http://ckan:3000/api/action

if [ "$VENV_DIR" != "" ]; then
  . ${VENV_DIR}/bin/activate
fi

add_user_if_needed () {
    echo "Adding user '$2' ($1) with email address [$3]"
    ckan_cli user "$1" | grep "$1" || ckan_cli user add "$1"\
        fullname="$2"\
        email="$3"\
        password="${4:-Password123!}"
}

# We know the "admin" sysadmin account exists, so we'll use her API KEY to create further data
API_KEY=$(ckan_cli user admin | tr -d '\n' | sed -r 's/^(.*)apikey=(\S*)(.*)/\2/')
CURL="curl -L -s --header 'Authorization: ${API_KEY}'"

# Creating test data hierarchy which creates organisations assigned to datasets
ckan_cli create-test-data hierarchy

# Creating basic test data which has datasets with resources
ckan_cli create-test-data

add_user_if_needed organisation_admin email=organisation_admin@localhost
add_user_if_needed publisher email=publisher@localhost
add_user_if_needed foodie email=foodie@localhost
add_user_if_needed group_admin email=group_admin@localhost
add_user_if_needed walker email=walker@localhost

echo "Updating annakarenina to use department-of-health Organisation:"
package_owner_org_update=$( \
    $CURL --data "id=annakarenina&organization_id=department-of-health" \
    ${CKAN_ACTION_URL}/package_owner_org_update
)
echo ${package_owner_org_update}

echo "Updating organisation_admin to have admin privileges in the department-of-health Organisation:"
organisation_admin_update=$( \
    $CURL --data "id=department-of-health&username=organisation_admin&role=admin" \
    ${CKAN_ACTION_URL}/organization_member_create
)
echo ${organisation_admin_update}

echo "Updating publisher to have editor privileges in the department-of-health Organisation:"
publisher_update=$( \
    $CURL --data "id=department-of-health&username=publisher&role=editor" \
    ${CKAN_ACTION_URL}/organization_member_create
)
echo ${publisher_update}

echo "Updating foodie to have admin privileges in the food-standards-agency Organisation:"
foodie_update=$( \
    $CURL --data "id=food-standards-agency&username=foodie&role=admin" \
    ${CKAN_ACTION_URL}/organization_member_create
)
echo ${foodie_update}

echo "Creating non-organisation group:"
group_create=$( \
    $CURL --data "name=silly-walks" \
    ${CKAN_ACTION_URL}/group_create
)
echo ${group_create}

echo "Updating group_admin to have admin privileges in the silly-walks group:"
group_admin_update=$( \
    $CURL --data "id=silly-walks&username=group_admin&role=admin" \
    ${CKAN_ACTION_URL}/group_member_create
)
echo ${group_admin_update}

echo "Updating walker to have editor privileges in the silly-walks group:"
walker_update=$( \
    $CURL --data "id=silly-walks&username=walker&role=editor" \
    ${CKAN_ACTION_URL}/group_member_create
)
echo ${walker_update}

if [ "$VENV_DIR" != "" ]; then
  deactivate
fi

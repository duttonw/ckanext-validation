Feature: Resource validation

    Scenario: As an editor, I can create and update a resource with an uploaded validation schema
        Given "TestOrgEditor" as the persona
        When I log in
        And I open the new resource form for dataset "warandpeace"
        And I attach the file "test.csv" to "upload"
        And I fill in "name" with "Test validation schema"
        And I fill in "description" with "Testing validation schema"
        And I attach the file "test_schema.json" to "schema_upload"
        And I press the element with xpath "//button[contains(@class, 'btn-primary')]"
        Then I should see "Test validation schema" within 2 seconds

        When I click the link with text that contains "Test validation schema"
        When I click the link with text that contains "Manage"
        Then I should see text containing quotes `"fields": [`
        And I should see text containing quotes `"name": "field1"`
        And I should see text containing quotes `"name": "field2"`

        When I click the link with text that contains "Test validation schema"
        When I click the link with text that contains "Manage"
        And I attach the file "test_schema2.json" to "schema_upload"
        And I press the element with xpath "//button[contains(@class, 'btn-primary')]"
        Then I should see "Test validation schema" within 2 seconds
        When I click the link with text that contains "Test validation schema"
        When I click the link with text that contains "Manage"
        Then I should see text containing quotes `"fields": [`
        And I should see text containing quotes `"name": "field1"`
        And I should see text containing quotes `"name": "field2"`
        And I should see text containing quotes `"title": "First column"`
        And I should see text containing quotes `"title": "Second column"`


    Scenario: As an editor, I can create and update a resource with validation options
        Given "TestOrgEditor" as the persona
        When I log in
        And I open the new resource form for dataset "warandpeace"
        And I attach the file "test.csv" to "upload"
        And I fill in "name" with "Test validation options"
        And I fill in "description" with "Testing validation options"
        And I attach the file "test_schema.json" to "schema_upload"
        And I fill in "validation_options" with "{"headers": 1}"
        And I execute the script "document.getElementById('field-format').value='CSV'"
        And I press the element with xpath "//button[contains(@class, 'btn-primary')]"
        Then I should see "Test validation options" within 2 seconds

        When I click the link with text that contains "Test validation options"
        When I click the link with text that contains "Manage"
        Then I should see text containing quotes `"headers": 1`

        When I click the link with text that contains "Test validation options"
        When I click the link with text that contains "Manage"
        And I fill in "validation_options" with "{"delimiter": ","}"

        And I press the element with xpath "//button[contains(@class, 'btn-primary')]"
        Then I should see "Test validation options" within 2 seconds
        When I click the link with text that contains "Test validation options"
        When I click the link with text that contains "Manage"
        Then I should see text containing quotes `"delimiter": ","`


    Scenario: As an editor, I can create a resource with a valid CSV and see a success status
        Given "TestOrgEditor" as the persona
        When I log in
        And I open the new resource form for dataset "warandpeace"
        And I attach the file "test.csv" to "upload"
        And I fill in "name" with "Test valid CSV create"
        And I attach the file "test_schema.json" to "schema_upload"
        And I fill in "description" with "Testing validation that should pass"
        And I execute the script "document.getElementById('field-format').value='CSV'"
        And I press the element with xpath "//button[contains(@class, 'btn-primary')]"
        Then I should see "Test valid CSV" within 2 seconds
        When I click the link with text that contains "Test valid CSV"
        Then I should see "Validation status" within 2 seconds
        And I should see "success" within 2 seconds
        And I should not see "failure" within 2 seconds
        And I should see a validation timestamp

    Scenario: As an editor, I can update a resource with a valid CSV and see a success status
        Given "TestOrgEditor" as the persona
        When I log in
        And I open the new resource form for dataset "warandpeace"
        And I attach the file "invalid.csv" to "upload"
        And I fill in "name" with "Test valid CSV update"
        When I fill in "description" with "Testing validation that should pass on update"
        And I press the element with xpath "//button[contains(@class, 'btn-primary')]"
        Then I should see "Test valid CSV update" within 2 seconds
        When I click the link with text that contains "Test valid CSV update"
        When I click the link with text that contains "Manage"
        And I attach the file "test.csv" to "upload"
        And I attach the file "test_schema.json" to "schema_upload"
        And I press the element with xpath "//button[contains(@class, 'btn-primary')]"
        When I click the link with text that contains "Test valid CSV update"
        Then I should see "Validation status" within 2 seconds
        And I should see "success" within 2 seconds
        And I should not see "failure" within 2 seconds
        And I should see a validation timestamp


    Scenario: As an editor, I can update a resource with an invalid CSV and see a validation error
        Given "TestOrgEditor" as the persona
        When I log in
        And I open the new resource form for dataset "warandpeace"
        And I attach the file "test.csv" to "upload"
        And I fill in "name" with "Test invalid CSV update"
        And I attach the file "test_schema.json" to "schema_upload"
        And I fill in "description" with "Testing validation that should fail on update"
        And I press the element with xpath "//button[contains(@class, 'btn-primary')]"
        Then I should see "Test invalid CSV update" within 2 seconds
        When I click the link with text that contains "Test invalid CSV update"
        When I click the link with text that contains "Manage"
        And I attach the file "invalid.csv" to "upload"
        And I press the element with xpath "//button[contains(@class, 'btn-primary')]"
        Then I should see "The form contains invalid entries" within 2 seconds
        And I should see "There are validation issues with this file" within 2 seconds
        When I click the link with text that contains "report"
        Then I should see "Data Validation Report" within 2 seconds
        Then I should see "Incorrect Label" within 2 seconds
        Then I should see "Extra Label" within 2 seconds
        Then I should see "Extra Cell" within 2 seconds

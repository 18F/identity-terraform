# `snow_incident` - ServiceNow Incident Generation SNS Topic

TL;DR - Create a ServiceNow Incident when a CloudWatch alarm (or other event) is triggered.

This Terraform module is designed to create a Lambda function, containing Python code, which will POST a message to ServiceNow and raise an incident.

Created resources:
- Lambda function + IAM role/policy
- Empty SSM snow_username and snow_password parameters (See below how to set values)
- CloudWatch log group
- SNS execution permission for the Lambda
- SNS topic
- SNS topic subscription

## Use
### Example Module

~~~hcl
module "snow_incident_topic" {
  source = "github.com/18F/identity-terraform/snow_incident?ref=main"

  name                  = "snow_incident_topic"
  topic_name            = "snow-incident"
  snow_incident_url     = "https://something.servicenowservices.com/api/some/path"
  snow_category         = "SERVICENOW CATEGORY NAME"
  snow_subcategory      = "SERVICENOW SUBCATEGORY NAME"
  snow_assignment_group = "SERVICENOW ASSIGNMENT GROUP NAME"
  snow_parameter_base   = "/account/snow_incident"
}
~~~

### Terraform Variables

Unfortunately a lot of parameters must be set to use this module.   Fortunately most should be provided
by ServiceNow as part of integration.

* `name` - Name of the Lambda function.
* `topic_name` - SNS topic name
* `snow_incident_url` - ServiceNow URL to POST to (maps to `SNOW_INCIDENT_URL` environment variable)
* `snow_category` - ServiceNow category name (maps to `SNOW_CATEGORY` environment variable)
* `snow_subcategory` - ServiceNow sub-category name (maps to `SNOW_SUBCATEGORY` environment variable)
* `snow_assignment_group` - ServiceNow group to assign the issue to (maps to `SNOW_ASSIGNMENT_GROUP` environment variable)
* `snow_parameter_base` - SSM Parameter Store base path, starting with `/` - The `snow_username` and `snow_password` should be set under this path (maps to `SNOW_PARAMETER_BASE` environment variable)

### Configuring Authentication in SSM Parameter Store

After first applied, you must populate the `snow_username` and `snow_password` parameters.  This only needs to be done once.

With `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` set (explicitly or through a tool like `aws-vault`), run the following to populate authentication info: (replace `{snow_parameter_base}` with the value used in Terraform and SNOW_USERNAME/SNOW_PASSWORD with their respective values provided by ServiceNow support)

~~~sh
$ aws ssm put-parameter --name {snow_parameter_base}/snow_username --overwrite --value SNOW_USERNAME
$ aws ssm put-parameter --name {snow_parameter_base}/snow_password --overwrite --value SNOW_PASSWORD
~~~

## Testing

To run basic unit tests: (Requires Python 3)
~~~
./snow_incident_test.py
~~~

CLI access to AWS (using a valid `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) is required
to test locally, and the SSM parameters `{snow_parameter_base}/snow_username` and `{snow_parameter_base}/snow_password`
must be set.

Alternately, to support testing, if the SNOW_USERNAME ane SNOW_PASSWORD environment
variables are set, SSM Parameter Store access is skipped.  This is provided for testing
and should NOT be done in production.

~~~sh
# Set required environment variables - Replace {} templates below
$ export SNOW_INCIDENT_URL={snow_incident_url}
$ export SNOW_CATEGORY={snow_category_name}
$ export SNOW_SUBCATEGORY={snow_subcategory_name}
$ export SNOW_ASSIGNMENT_GROUP={snow_assignment_group_name}
$ export SNOW_PARAMETER_BASE={snow_parameter_base}  # Ignored if using SNOW_USERNAME/SNOW_PASSWORD

# Optional - Use of username and password set in environment instead of SSM Parameter Store
$ export SNOW_USERNAME={snow_username}
$ export SNOW_PASSWORD={snow_password}

# Use the Python REPL to test
$ python3 snow_incident.py

> import snow_incident
> settings = snow_incident.get_env_settings()
> body = snow_incident.create_body(settings["default_body"], "Test Subject", "Test Description")
> auth = snow_incident.get_auth(settings["parameter_base"]
> incident = snow_incident.create_incident(settings["url"], auth, body)
> print(f"Created incident {incident['result']['number']}")

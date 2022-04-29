_(This information is pulled directly from the README for the `null_lambda` module.)_

# `null_lambda`

This Terraform module creates an AWS Lambda Function (from a given path and source file), but uses a `null_resource` as the trigger for compressing it into a ZIP file and passing said ZIP file's SHA to the `aws_lambda_function` resources. This is used to address a few key issues:

1. Purely using a ZIP file containing the Lambda source code means either specifying a location outside of the repo for the ZIP to exist in, or tracking the ZIP file in `git`. Using an `archive_file` data source -- and adding said ZIP file to `.gitignore` -- ensures that the file is managed entirely in Terraform.
2. Terraform will not know to look for changes to the files within the ZIP file used as the `archive_file` data source; it will only create a _new_ ZIP file if the previous one is removed. Unless one remembers to either re-ZIP the code, or delete the ZIP so that Terraform can recreate it, the function won't be updated when simply making changes to the source code itself.
3. When purely using an `archive_file` data source for creating/updating a Lambda function, the output of `terraform plan` will always show pending changes when the `archive_file` is [re]created -- regardless of whether or not the files within have actually changed:
  ```
   # module.main.aws_lambda_function.example_function will be updated in-place
   ~ resource "aws_lambda_function" "example_function" {
     ~ last_modified = "2022-04-06T19:32:04.000+0000" -> (known after apply)
     ~ source_code_hash = "AnOriginalHashValue09jshfkgbkhjx36ferjkbf=" -> "ADifferentHashValue3785yhutrefg7gt358vbhe="
  ```
  Thus, if multiple sources are acting on a ZIP file (i.e. an automated pipeline vs. an engineer running Terraform on an ad hoc basis), Terraform will constantly show a `plan` with pending changes, even when no _actual_ changes have been made to the source code itself.

`null_resource.source_hash_check` is used to monitor the Base64-encoded SHA256 hash of the main source code file, and will cause the `archive_file` resource to _always_ create a new ZIP file -- but only if updates are _actually_ made to the function's source code file.

## Example

```hcl
module "example_lambda_function" {
  source = "github.com/18F/identity-terraform//null_lambda?ref=main"

  source_code_filename  = "lambda_function.py"
  source_dir            = "${path.module}/src/"
  zip_filename          = var.example_lambda_code
  external_role_arn     = aws_iam_role.example_lambda_role.arn
  function_name         = "${var.example_lambda_name}-function"
  description           = "Sample AWS Lambda Function"
  handler               = "lambda_function.lambda_handler"
  memory_size           = 3008
  runtime               = "python3.8"
  timeout               = 300
  perm_id               = "${var.example_lambda_name}-lambda-permission"
  permission_principal  = ["sns.amazonaws.com"]
  permission_source_arn = data.aws_sns_topic.example_sns_topic.arn

  env_var_map = {
    EXAMPLE_ONE  = 1,
    EXAMPLE_TWO  = "TWO",
  }
}
```

## Variables

`source_code_filename` - (REQUIRED) Name (with extension) of file containing function source code.
`source_dir` - (REQUIRED) Name of directory where source_code_filename + any other files to be added to the ZIP file reside.
`zip_filename` - (OPTIONAL) Custom name for the ZIP file containing Lambda source code. Will default to `function_name` if not specified here.
`external_role_arn` - (OPTIONAL) ARN of an external IAM role used by the Lambda function, one with (at least) the **sts:AssumeRole** permission. If not specified, a role named **`function_name`-lambda-role** with said basic permission will be created and used instead.
`function_name` - (REQUIRED) Name of the Lambda function.
`description` - (REQUIRED) Description of the Lambda function.
`handler` - (REQUIRED) Handler for the Lambda function.
`memory_size` - (REQUIRED) Memory (in MB) available to the Lambda function.
`runtime` - (REQUIRED) Runtime used by the Lambda function.
`timeout` - (REQUIRED) Timeout value for the Lambda function.
`env_var_map` - (OPTIONAL) Map of environment variables used by the Lambda function, if any.
`perm_id` - (OPTIONAL) ID/name of Statement identifying the permission for the function. Will default to **`function_name`-lambda-permission** if not specified here.
`permission_principal` - (OPTIONAL) Service principal for Lambda permission, e.g. **events.amazonaws.com**. ONLY use if desiring to create an AWS Lambda Permission. _Must be in **list** format,_ as it is used with `for_each` to create the Permission on a conditional basis.
`permission_source_arn` - (OPTINAL) ARN of resource referenced by/connected to principal for Lambda permission. ONLY use if desiring to create an AWS Lambda Permission.

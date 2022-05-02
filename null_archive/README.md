# `null_archive`

This Terraform module uses a `null_resource` as a trigger for compressing the code for an AWS Lambda function into a ZIP file (as an `archive_file` data source). This is to address a few key issues:

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
module "smart_archive_file" {
  source = "github.com/18F/identity-terraform//null_archive?ref=main"

  source_code_filename  = "lambda_function.py"
  source_dir            = "${path.module}/src/"
  zip_filename          = var.example_lambda_code
}

resource "aws_lambda_function" "sample_lambda" {
  function_name    = "${var.env}-sample-lambda-${data.aws_region.current.name}"
  description      = "Sample AWS Lambda Function"
  filename         = module.smart_archive_file.zip_output_path
  source_code_hash = module.smart_archive_file.zip_output_base64sha256
  runtime          = "python3.9"
  handler          = "main.lambda_handler"
  timeout          = 90
  memory_size      = 128
  role             = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      env             = "${var.env}"
      log_group_name  = aws_cloudwatch_log_group.example_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.example_log_stream.name
      region          = data.aws_region.current.name
    }
  }
}
```

## Variables

`source_code_filename` - (REQUIRED) Name (with extension) of file containing function source code.
`source_dir` - (REQUIRED) Name of directory where source_code_filename + any other files to be added to the ZIP file reside.
`zip_filename` - (REQUIRED) Desired name (WITHOUT extension) of resultant output ZIP file.

## Outputs

`zip_output_path` - Output path/filename of ZIP file created from source code filename.
`zip_output_base64sha256` - base64-encoded SHA256 checksum of ZIP file.
# `state_bucket`

This module manages the terraform remote state S3 bucket and remote state
DynamoDB lock table. These are tricky resources to manage because there is a
chicken and egg bootstrapping problem involved in creating them. Terraform
needs the remote state bucket to exist before it runs for the first time. But
we also do want to manage this bucket in terraform so that it doesn't diverge
from the expected configuration (encryption, versioning, etc.).

For bootstrapping, the remote state bucket will be automatically created by
`bin/tf-deploy` using `bin/configure_state_bucket.sh`. Then, import those
resources into terraform for management by running the `terraform import`
commands found in comments in [./main.tf](./main.tf).


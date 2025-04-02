## PLEASE NOTE: The original `git2s3` Quick Start templates/repos/etc. have been deprecated, so new deployments of this module may no longer work as of December 2024. We recommend migrating from this module to [the `git2s3_sync` module](https://github.com/18F/identity-terraform/tree/main/git2s3_sync), also found within this repo, which builds all resources within via Terraform (instead of CloudFormation) and no longer relies on the now-deprecated Quick Start code/sources.

# `git2s3_artifacts`

This Terraform module is a wrapper around the ["Git webhooks on the AWS Cloud" Quick Start Deployment](https://aws-quickstart.github.io/quickstart-git2s3/), a CloudFormation stack, here used as the resource `aws_cloudformation_stack.git2s3`. The Stack builds the necessary architecture -- an API gateway, Lambda function, S3 buckets, etc. -- for `git push` operations to trigger a retrieval, zip, and S3 upload of a given third-party repository.

In addition to the original deployment Stack, this builds:

1. A `public-artifacts` S3 bucket, which is accessible by resources in the AWS account where it is created, and by resources in any other AWS accounts specified with the `external_account_ids` list variable.
2. A key, `git2s3/OutputBucketName`, within the `public-artifacts` bucket. Its content is the name of the S3 bucket `OutputBucket`, which is created by the `git2s3` Stack as the upload destination for the repository zips.

This module can be used in cases where multiple AWS accounts need access to the code from a particular third-party repo, but one or more of those accounts is unable/not permitted to communicate with third-party services, such as GitHub; thus, it/they must be able to retrieve it from an AWS resource within the same organization/ownership boundary.

## Note

For the purposes of this module, the CloudFormation stack builds with its parameters hard-coded thusly:

```
    AllowedIps          = regex(
                            "^[0-9.,\\/]+\\/32",
                            substr(join(",",data.github_ip_ranges.ips.git), 0, 512)
                          )
    QSS3BucketName      = "aws-quickstart"
    OutputBucketName    = ""
    ScmHostnameOverride = ""
    ExcludeGit          = "True"
    VPCId               = ""
    CustomDomainName    = ""
    QSS3BucketRegion    = "us-east-1"
    ApiSecret           = ""
    QSS3KeyPrefix       = "quickstart-git2s3/"
    VPCCidrRange        = ""
    SubnetIds           = ""
```

The `regex()` string operation is used to trim down the list of IP addresses from the `github_ip_ranges.ips.git` data source, as explained below:

1. By default, the list begins with larger ranges (e.g. `/20`, `/22`, etc.), and then contains a large array of individual `/32` addresses. At the time of this writing, the resulting string -- with commas joining the addresses -- is ~592 characters in length.
2. The `AllowedIps` parameter is used within the CloudFormation stack to configure the AWS API Gateway resource, specifying the source IP ranges that the API will accept requests from. However, this `$stageVariable` must be *512 characters or less*; as the default list of IP ranges is larger than this, CloudFormation will refuse to accept it as an input parameter.
3. To ensure that the resultant string for `AllowedIps` is under 512 characters, the comma-separated list of IPs created via `join()` is trimmed down to 512 characters by the `substr()` function; the `regex()` operation takes that resultant string and truncates it after the last `/32` address, ensuring that there won't be any partial addresses which would cause syntax errors.

## Example

```hcl
module "git2s3_src" {
  source = "github.com/18F/identity-terraform//git2s3_artifacts?ref=main"

  git2s3_stack_name    = "CodeSync-IdentityBase"
  external_account_ids = [
    "000011112222",
    "333344445555",
    "666677778888",
  ]
  bucket_name_prefix = "login-gov"
}

module "main" {
  source     = "../module"
  depends_on = [module.git2s3_src.output_bucket]
}
```

## Variables

- `bucket_name_prefix` - **string**: REQUIRED. First substring in names for log_bucket, inventory_bucket, and the public-artifacts bucket.
- `log_bucket_name` - **string**: (OPTIONAL) Specific name of the bucket used for S3 logging. Will default to `$bucket_name_prefix.s3-access-logs.$account_id-$region` if not explicitly declared.
- `create_artifact_bucket` - **bool**: (OPTIONAL) Whether or not to create the public-artifacts bucket, and related resources, within this module. Set to 'false' if managing said bucket in a separate/parent module.
- `region` - **string**: AWS Region. Defaults to `us-west-2`.
- `inventory_bucket_name` - **string**: (OPTIONAL) Specific name of the S3 bucket used for collecting the S3 Inventory reports. Will default to `$bucket_name_prefix.s3-inventory.$account_id-$region` if not explicitly declared.
- `sse_algorithm` - **string**: SSE algorithm to use to encrypt reports in S3 Inventory bucket. Defaults to `aws:kms`.
- `git2s3_stack_name` - **string**: REQUIRED. Name for the `git2s3` CloudFormation Stack.
- `external_account_ids` - **list(string)**: (OPTIONAL) List of additional AWS account IDs, if any, to be permitted access to the public-artifacts bucket.

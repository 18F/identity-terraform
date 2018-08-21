resource "random_string" "suffix" {
  length = 8
  special = false
}
resource "aws_kinesis_stream" "datastream" {
    name = "${var.name_prefix}_${random_string.suffix.result}"
    shard_count = "${var.kinesis_shard_count}"
    retention_period = "${var.kinesis_retention_hours}"
    encryption_type = "KMS",
    kms_key_id="${var.kinesis_kms_key_id}"

    shard_level_metrics = [
        "ReadProvisionedThroughputExceeded",
        "WriteProvisionedThroughputExceeded"
    ]
}

data "aws_iam_policy_document" "assume_role" {
    statement {
        sid = "AssumeRole"
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["logs.${var.aws_cloudwatch_region}.amazonaws.com"]
        }
    }
}
data "aws_iam_policy_document" "cloudwatch_access" {
   statement {
     sid = "KinesisPut" 
     effect = "Allow"
     actions = [
       "kinesis:PutRecord"
     ]
     resources = [
       "${aws_kinesis_stream.datastream.arn}"
     ]
   }
}
resource "aws_iam_role" "cloudwatch_to_kinesis" {
 name = "${var.name_prefix}_${random_string.suffix.result}"
 path = "/"
 assume_role_policy = "${data.aws_iam_policy_document.redshift_admin_assume.json}"
}

resource "aws_iam_policy" "cloudwatch_access" {
    name        = "${var.name_prefix}_${random_string.suffix.ressult}"
    path        = "/"
    description = "Cloudwatch access"
    policy = "${data.aws_iam_policy_document.cloudwatch_access.json}"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
    role       = "${aws_iam_role.cloudwatch_to_kinesis.name}"
    policy_arn = "${aws_iam_policy.cloudwatch_access.arn}"
}

resource "aws_cloudwatch_log_destination" "datastream" {
    name = "${var.name_prefix}_${random_string.suffix.ressult}"
    role_arn = "${aws_iam_role.cloudwatch_to_kinesis.arn}"
    target_arn = "${aws_kinesis_stream.datastream.arn}"
}

data "aws_iam_policy_document" "subscription" {
    statement {
        sid = "PutSubscription"
        actions = ["logs:PutSubscriptionFiler"]

        principals {
            type        = "AWS"
            identifiers = ["${var.cloudwatch_source_account_id}"]
        }

        resources = [
            "${aws_cloudwatch_log_destination.datastream.arn}"
        ]
    }
}

resource "aws_cloudwatch_log_destination_policy" "subscription" {
    destination_name = "${aws_cloudwatch_log_destination.datastream.name}"
    access_policy = "${data.aws_iam_policy_document.subscription.json}"
}

#TODO: this needs a different provider or in another module
#may not work until the stream and the permissions are in place
#resource is in the source account
resource "aws_cloudwatch_log_subscription_filter" "kinesis" {
    name = "${var.name_prefix}_${random_string.suffix.result}"
    log_group_name = "${var.cloudwatch_log_group_name}"
    filter_pattern = "${var.clouddwatch_filter_pattern}"
    destination_arn = "${aws_kinesis_stream.datastream.arn}"
}
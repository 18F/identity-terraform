
resource "aws_kinesis_stream" "datastream" {
    name = "${var.env_name}-${var.stream_name}"
    shard_count = "${var.kinesis_shard_count}"
    retention_period = "${var.kinesis_retention_hours}"
    encryption_type = "KMS",
    kms_key_id="${var.kinesis_kms_key_id}"

    shard_level_metrics = [
        "ReadProvisionedThroughputExceeded",
        "WriteProvisionedThroughputExceeded"
    ]
    
    tags {
        environment = "${var.env_name}"
    }
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
 name = "${var.env_name}-${var.stream_name}"
 path = "/"
 assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "cloudwatch_access" {
    name = "cloudwatch"
    role = "${aws_iam_role.cloudwatch_to_kinesis.name}"
    policy = "${data.aws_iam_policy_document.cloudwatch_access.json}"
}

resource "aws_cloudwatch_log_destination" "datastream" {
    name = "${var.env_name}-${var.stream_name}"
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


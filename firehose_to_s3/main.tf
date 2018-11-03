resource "aws_cloudwatch_log_group" "log_group" {
    name = "/aws/kinesisfirehose/${var.env_name}-${var.stream_name}"
    retention_in_days = "${var.log_retention_in_days}"

    tags {
        environment = "${var.env_name}"
    }
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "S3Delivery"
  log_group_name = "${aws_cloudwatch_log_group.log_group.name}"
}

resource "aws_kinesis_firehose_delivery_stream" "kinesis_s3" {
  name = "${var.env_name}-${var.stream_name}"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = "${var.datastream_source_arn}"
    role_arn = "${aws_iam_role.firehose_to_s3.arn}"
  }

  extended_s3_configuration {
    role_arn   = "${aws_iam_role.firehose_to_s3.arn}"
    bucket_arn = "arn:aws:s3:::${var.firehose_bucket_name}"
    prefix = "${var.firehose_bucket_prefix}/"
    buffer_size = "${var.buffer_size}"
    buffer_interval = "${var.buffer_interval}"
    compression_format = "GZIP"
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "/aws/kinesisfirehose/${var.env_name}-${var.stream_name}"
      log_stream_name = "S3Delivery"
    }
    s3_backup_mode = "Enabled"
    s3_backup_configuration {
      bucket_arn = "${var.s3_backup_bucket_arn}"
      prefix = "${var.s3_backup_bucket_prefix}"
      role_arn = "${aws_iam_role.firehose_to_s3.arn}"
      compression_format = "GZIP"
    }
    kms_key_arn = "${var.s3_key_arn}"
    processing_configuration = [
      {
        enabled = "true"
        processors = [
          {
            type = "Lambda"
            parameters = [
              {
                parameter_name = "LambdaArn"
                parameter_value = "${var.lambda_arn}:$LATEST"
              }
            ]
          }
        ]
      }
    ]
  }
}

data "aws_iam_policy_document" "assume_role" {
    statement {
        sid = "AssumeRole"
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["firehose.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "glue" {
   statement {
     sid = "Glue" 
     effect = "Allow"
     actions = [
       "glue:GetTableVersions"
     ]
     resources = [
       "*"
     ]
   }
}

data "aws_iam_policy_document" "s3" {
   statement {
     sid = "S3" 
     effect = "Allow"
     actions = [
       "s3:AbortMultipartUpload",
       "s3:GetBucketLocation",
       "s3:GetObject",
       "s3:ListBucket",
       "s3:ListBucketMultipartUploads",
       "s3:PutObject"
     ]
     resources = [
        "${var.firehose_bucket_arn}",
        "${var.firehose_bucket_arn}/*",
        "${var.s3_backup_bucket_arn}",
        "${var.s3_backup_bucket_arn}/*"
     ]
   }
}

data "aws_iam_policy_document" "lambda" {
   statement {
     sid = "Lambda" 
     effect = "Allow"
     actions = [
       "lambda:InvokeFunction",
       "lambda:GetFunctionConfiguration"
     ]
     resources = [
       "${var.lambda_arn}:$LATEST"
     ]
   }
}

data "aws_iam_policy_document" "s3kms" {
   statement {
     sid = "s3kms" 
     effect = "Allow"
     actions = [
       "kms:GenerateDataKey",
       "kms:Decrypt"
     ]
     resources = [
       "${var.s3_key_arn}"
     ]
     condition {
       test = "StringEquals"
       variable = "kms:ViaService"

       values = [
         "s3.${var.region}.amazonaws.com"
       ]
     }
     condition {
       test = "StringLike"
       variable = "kms:EncryptionContext:aws:s3:arn"

       values = [
         "${var.firehose_bucket_arn}/${var.firehose_bucket_prefix}*",
         "${var.s3_backup_bucket_arn}/${var.s3_backup_bucket_prefix}*"
       ]
     }
   }
}

data "aws_iam_policy_document" "cloudwatch" {
   statement {
     sid = "Cloudwatch" 
     effect = "Allow"
     actions = [
       "logs:PutLogEvents"
     ]
     resources = [
       "${aws_cloudwatch_log_group.log_group.arn}"
     ]
   }
}

data "aws_iam_policy_document" "kinesis" {
   statement {
     sid = "Kinesis" 
     effect = "Allow"
     actions = [
       "kinesis:DescribeStream",
       "kinesis:GetShardIterator",
       "kinesis:GetRecords"
     ]
     resources = [
       "${var.datastream_source_arn}"
     ]
   }
}

data "aws_iam_policy_document" "deliverystreamkms" {
   statement {
     sid = "deliverystreamkms" 
     effect = "Allow"
     actions = [
       "kms:Decrypt"
     ]
     resources = [
       "${var.stream_key_arn}"
     ]
     condition {
       test = "StringEquals"
       variable = "kms:ViaService"

       values = [
         "kinesis.${var.region}.amazonaws.com"
       ]
     }
     condition {
       test = "StringLike"
       variable = "kms:EncryptionContext:aws:kinesis:arn"

       values = [
         "${var.datastream_source_arn}"
       ]
     }
   }
}

resource "aws_iam_role" "firehose_to_s3" {
  name = "${var.env_name}-${var.stream_name}"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "glue" {
  name = "glue"
  role = "${aws_iam_role.firehose_to_s3.id}"
  policy = "${data.aws_iam_policy_document.glue.json}"
}

resource "aws_iam_role_policy" "s3" {
  name = "s3"
  role = "${aws_iam_role.firehose_to_s3.id}"
  policy = "${data.aws_iam_policy_document.s3.json}"
}

resource "aws_iam_role_policy" "lambda" {
  name = "lambda"
  role = "${aws_iam_role.firehose_to_s3.id}"
  policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_iam_role_policy" "s3kms" {
  name = "s3kms"
  role = "${aws_iam_role.firehose_to_s3.id}"
  policy = "${data.aws_iam_policy_document.s3kms.json}"
}

resource "aws_iam_role_policy" "deliverystreamkms" {
  name = "deliverystreamkms"
  role = "${aws_iam_role.firehose_to_s3.id}"
  policy = "${data.aws_iam_policy_document.deliverystreamkms.json}"
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "cloudwatch"
  role = "${aws_iam_role.firehose_to_s3.id}"
  policy = "${data.aws_iam_policy_document.cloudwatch.json}"
}

resource "aws_iam_role_policy" "kinesis" {
  name = "kinesis"
  role = "${aws_iam_role.firehose_to_s3.id}"
  policy = "${data.aws_iam_policy_document.kinesis.json}"
}

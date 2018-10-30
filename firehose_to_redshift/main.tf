data "aws_caller_identity" "current" {}

resource "aws_kinesis_firehose_delivery_stream" "rs_stream" {
    name = "${var.env_name}-${var.stream_name}"
    destination = "redshift"

    kinesis_source_configuration {
      kinesis_stream_arn = "${var.datastream_source_arn}"
      role_arn = "${aws_iam_role.firehose_to_redshift.arn}"
  }

    s3_configuration {
        role_arn = "${aws_iam_role.firehose_to_redshift.arn}"
        bucket_arn = "${var.intermediate_bucket_arn}"
        buffer_size = "${var.buffer_size}"
        buffer_interval = "${var.buffer_interval}"
        compression_format = "GZIP"
        kms_key_arn = "${var.s3_temp_key_arn}"
    }

    redshift_configuration {
        role_arn = "${aws_iam_role.firehose_to_redshift.arn}"
        cluster_jdbcurl = "${var.redshift_jdbc}"
        username = "${var.redshift_username}"
        password = "${var.redshift_password}"
        data_table_name = "${var.redshift_table}"
        copy_options = "${var.copy_options}" 
        data_table_columns = "${var.columns}"
        s3_backup_mode = "Enabled"
        s3_backup_configuration {
            bucket_arn = "${var.s3_backup_bucket_arn}"
            prefix = "${var.s3_backup_bucket_prefix}"
            role_arn = "${aws_iam_role.firehose_to_redshift.arn}"
            compression_format = "GZIP"
        }
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
        "${var.s3_backup_bucket_arn}",
        "${var.s3_backup_bucket_arn}/*",
        "arn:aws:s3:::%FIREHOSE_BUCKET_NAME%",
        "arn:aws:s3:::%FIREHOSE_BUCKET_NAME%/*"
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
       "${var.s3_temp_key_arn}"
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
       "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/${var.env_name}-${var.stream_name}:log-stream:*"
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

resource "aws_iam_role" "firehose_to_redshift" {
  name = "${var.env_name}-${var.stream_name}"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "glue" {
  name = "glue"
  role = "${aws_iam_role.firehose_to_redshift.id}"
  policy = "${data.aws_iam_policy_document.glue.json}"
}

resource "aws_iam_role_policy" "s3" {
  name = "s3"
  role = "${aws_iam_role.firehose_to_redshift.id}"
  policy = "${data.aws_iam_policy_document.s3.json}"
}

resource "aws_iam_role_policy" "lambda" {
  name = "lambda"
  role = "${aws_iam_role.firehose_to_redshift.id}"
  policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_iam_role_policy" "s3kms" {
  name = "s3kms"
  role = "${aws_iam_role.firehose_to_redshift.id}"
  policy = "${data.aws_iam_policy_document.s3kms.json}"
}

resource "aws_iam_role_policy" "deliverystreamkms" {
  name = "deliverystreamkms"
  role = "${aws_iam_role.firehose_to_redshift.id}"
  policy = "${data.aws_iam_policy_document.deliverystreamkms.json}"
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "cloudwatch"
  role = "${aws_iam_role.firehose_to_redshift.id}"
  policy = "${data.aws_iam_policy_document.cloudwatch.json}"
}

resource "aws_iam_role_policy" "kinesis" {
  name = "kinesis"
  role = "${aws_iam_role.firehose_to_redshift.id}"
  policy = "${data.aws_iam_policy_document.kinesis.json}"
}

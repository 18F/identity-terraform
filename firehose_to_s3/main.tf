data "aws_caller_identity" "current" {}

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
    kms_key_arn = "${var.kms_key_arn}"
    processing_configuration = [
      {
        enabled = "true"
        processors = [
          {
            type = "lambda"
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
        "arn:aws:s3:::${var.firehose_bucket_name}",
        "arn:aws:s3:::${var.firehose_bucket_name}/*",
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
     sid = "kms1" 
     effect = "Allow"
     actions = [
       "kms:GenerateDataKey",
       "kms:Decrypt"
     ]
     resources = [
       "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key:${var.kms_key_id}"
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
         "arn:aws:s3:::${var.firehose_bucket_name}/${var.firehose_bucket_prefix}*"
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
       "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/"
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
       "{aws_kinesis_firehose_delivery_stream.kinesis_s3.arn}"
     ]
   }
}

data "aws_iam_policy_document" "deliverystreamkms" {
   statement {
     sid = "kms2" 
     effect = "Allow"
     actions = [
       "kms:Decrypt"
     ]
     resources = [
       "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key:${var.kms_key_id}"
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
         "arn:aws:kinesis:${var.region}:${data.aws_caller_identity.current.account_id}:stream/${aws_kinesis_firehose_delivery_stream.kinesis_s3.name}"
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

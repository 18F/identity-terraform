resource "aws_kinesis_firehose_delivery_stream" "kinesis_s3" {
  name        = "${var.env_name}-${var.name}"
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
       "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.lambda_transform}:$LATEST"
     ]
   }
}

data "aws_iam_policy_document" "kms1" {
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
         "arn:aws:s3:::${var.firehose_bucket_name}/${var.firehose_prefix}*"
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

data "aws_iam_policy_document" "kms2" {
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
         "arn:aws:kinesis:${var.region}:${data.aws_caller_identity.current.account_id}:stream/${aws_kinesis_firehose_delivery_stream.kinesis_s3}"
       ]
     }
   }
}

resource "aws_iam_role" "firehose_to_s3" {
  name = "${var.env_name}-firehose-${var.stream_name}"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_attachment" "glue" {
  role = "${aws_iam_role.firehose_to_s3.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_role_attachment" "s3" {
  role = "${aws_iam_role.firehose_to_s3.name}"
  policy_arn = "${aws_iam_policy.s3.arn}"
}

resource "aws_iam_role_attachment" "lambda" {
  role = "${aws_iam_role.firehose_to_s3.name}"
  policy_arn = "${aws_iam_policy.lambda.arn}"
}

resource "aws_iam_role_attachment" "kms1" {
  role = "${aws_iam_role.firehose_to_s3.name}"
  policy_arn = "${aws_iam_policy.kms1.arn}"
}

resource "aws_iam_role_attachment" "kms2" {
  role = "${aws_iam_role.firehose_to_s3.name}"
  policy_arn = "${aws_iam_policy.kms2.arn}"
}

resource "aws_iam_role_attachment" "cloudwatch" {
  role = "${aws_iam_role.firehose_to_s3.name}"
  policy_arn = "${aws_iam_policy.cloudwatch.arn}"
}

resource "aws_iam_role_attachment" "kinesis" {
  role = "${aws_iam_role.firehose_to_s3.name}"
  policy_arn = "${aws_iam_policy.kinesis.arn}"
}

resource "aws_lambda_function" "transform" {
  s3_bucket = "${var.lambda_package_bucket}"
  s3_key = "${var.lambda_package_key}"
  function_name    = "${var.lambda_name}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "handler"
  source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  runtime          = "nodejs8.10"

  environment {
    variables = {
      environment = "${var.env_name}"
    }
  }
}

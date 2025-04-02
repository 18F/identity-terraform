locals {
  ip_regex = "^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\/(?:[0-2][0-9]|[3][0-2])"

  allowed_ips = var.allowed_ip_ranges == "" ? (
    regex("^[0-9.,\\/]+\\/32", substr(join(",", compact([
      for ip in data.github_ip_ranges.ips.git : try(regex(local.ip_regex, ip), "")
    ])), 0, 512))
  ) : var.allowed_ip_ranges
}

data "aws_iam_policy_document" "api_webhook_lambda" {
  statement {
    sid    = "AllowInvokeLambdaFunction"
    effect = "Allow"
    actions = [
      "lambda:InvokeAsync",
      "lambda:InvokeFunction"
    ]
    resources = [
      module.lambda_git2s3.lambda_arn
    ]
  }
}

data "aws_iam_policy_document" "api_webhook_assume" {
  statement {
    sid     = "APIGatewayServiceRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_webhook" {
  name               = "${var.git2s3_project_name}-api-webhook"
  assume_role_policy = data.aws_iam_policy_document.api_webhook_assume.json
}

resource "aws_iam_role_policy_attachment" "api_webhook_push" {
  role       = aws_iam_role.api_webhook.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy" "api_webhook_lambda" {
  name   = "${var.git2s3_project_name}-api-webhook-lambda"
  role   = aws_iam_role.api_webhook.id
  policy = data.aws_iam_policy_document.api_webhook_lambda.json
}

resource "aws_api_gateway_rest_api" "webhook" {
  body = jsonencode({
    swagger = "2.0"
    info = {
      title   = var.git2s3_project_name
      version = "2016-07-26T07:34:38Z"
    }
    schemes = [
      "https"
    ]
    paths = {
      "/gitpull" = {
        post = {
          consumes = [
            "application/json"
          ],
          produces = [
            "application/json"
          ],
          responses = {
            200 = {
              description = "200 response",
              schema = {
                "$ref" = "#/definitions/Empty"
              }
            }
          },
          x-amazon-apigateway-integration = {
            type        = "aws"
            credentials = aws_iam_role.api_webhook.arn
            responses = {
              default = {
                statusCode = "200"
              }
            }
            requestParameters = {
              "integration.request.header.X-Amz-Invocation-Type" = "'Event'"
            }
            passthroughBehavior = "when_no_templates"
            httpMethod          = "POST"
            uri = join("", [
              "arn:aws:apigateway:",
              data.aws_region.current.name,
              ":lambda:path//2015-03-31/functions/",
              module.lambda_git2s3.lambda_arn,
              "/invocations"
            ])
            requestTemplates = {
              "application/json" = join("", split("\n", file("${path.module}/apigateway-webhook.json")))
            }
          }
        }
      }
    }
    "securityDefinitions" = {
      sigv4 = {
        type                         = "apiKey",
        name                         = "Authorization",
        in                           = "header",
        x-amazon-apigateway-authtype = "awsSigv4"
      }
    }
    "definitions" = {
      Empty = {
        type = "object"
      }
    }
  })

  name = var.git2s3_project_name
}

resource "aws_api_gateway_deployment" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.webhook.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "webhook_prod" {
  deployment_id = aws_api_gateway_deployment.webhook.id
  rest_api_id   = aws_api_gateway_rest_api.webhook.id
  stage_name    = "Prod"

  variables = {
    outputBucket = aws_s3_bucket.codebuild_output.id
    secretId     = aws_secretsmanager_secret.ssh_key_pair.id
    allowedIps   = local.allowed_ips
  }

  depends_on = [
    aws_s3_bucket.codebuild_output
  ]
}

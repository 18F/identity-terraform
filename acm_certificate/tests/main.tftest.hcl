provider "aws" {

  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-west-2"
  s3_use_path_style           = false
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    logs           = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    acm            = "http://localhost:4566"
  }
}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

variables {
  domain_name = "example.com"
}

run "test_alternative_names" {

  variables {
    validation_zone_id = run.setup_tests.zone_id
  }
  assert {
    condition     = aws_acm_certificate.main.subject_alternative_names == toset(concat([var.domain_name], var.subject_alternative_names))
    error_message = "Certificate contains additional names"
  }
}

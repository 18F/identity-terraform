terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    external = {
      source  = "hashicorp/external"
    }
    github = {
      source  = "integrations/github"
    }
    null = {
      source  = "hashicorp/null"
    }
    template = {
      source  = "hashicorp/template"
    }
    newrelic = {
      source  = "newrelic/newrelic"
    }
  }
  required_version = ">= 0.13.7"
}

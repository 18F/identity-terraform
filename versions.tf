terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    archive = {
      source  = "hashicorp/archive"
    }
    external = {
      source  = "hashicorp/external"
    }
    null = {
      source  = "hashicorp/null"
    }
    template = {
      source  = "hashicorp/template"
    }
    github = {
      source  = "integrations/github"
    }
    newrelic = {
      source  = "newrelic/newrelic"
    }
  }
  required_version = ">= 0.13.7"
}

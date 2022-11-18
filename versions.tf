terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
    }
    external = {
      source = "hashicorp/external"
    }
    null = {
      source = "hashicorp/null"
    }
    github = {
      source = "integrations/github"
    }
    newrelic = {
      source = "newrelic/newrelic"
    }
  }
  required_version = ">= 1.3.5"
}

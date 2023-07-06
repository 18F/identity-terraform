terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.use1 ]
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

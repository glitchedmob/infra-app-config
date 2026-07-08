terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.53"
    }
    headscale = {
      source  = "awlsring/headscale"
      version = "~> 0.5"
    }
    uptimekuma = {
      source  = "breml/uptimekuma"
      version = "~> 0.3"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.10"
    }
  }
}

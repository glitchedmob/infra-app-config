terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.64"
    }
    headscale = {
      source  = "awlsring/headscale"
      version = "~> 0.5"
    }
    uptimekuma = {
      source  = "breml/uptimekuma"
      version = "~> 0.4"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.11"
    }
    json-formatter = {
      source  = "TheNicholi/json-formatter"
      version = "~> 0.1"
    }
    zitadel = {
      source  = "zitadel/zitadel"
      version = "~> 3.7"
    }
  }
}

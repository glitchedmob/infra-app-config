terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9.1"
    }
    vault = {
      source = "hashicorp/vault"
    }
    zitadel = {
      source = "zitadel/zitadel"
    }
  }
}

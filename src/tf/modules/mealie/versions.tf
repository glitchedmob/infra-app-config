terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }
    vault = {
      source = "hashicorp/vault"
    }
    zitadel = {
      source = "zitadel/zitadel"
    }
  }
}

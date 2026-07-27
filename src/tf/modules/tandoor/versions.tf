terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

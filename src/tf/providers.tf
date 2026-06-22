provider "aws" {
  region = var.aws_region
}

provider "headscale" {
  api_key  = var.headscale_api_key
  endpoint = "https://${var.headscale_host}"
}

provider "uptimekuma" {
  endpoint = var.uptimekuma_endpoint
  username = var.uptimekuma_username
  password = var.uptimekuma_password
}

provider "vault" {
  address         = "https://${var.openbao_host}"
  token           = var.openbao_token
  skip_tls_verify = true
}

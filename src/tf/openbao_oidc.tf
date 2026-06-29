data "aws_caller_identity" "current" {}

ephemeral "aws_ssm_parameter" "dex_openbao_client_secret" {
  arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/vm-workloads/lz/infra-vm-workloads/dex-client-openbao-secret"
}

resource "vault_jwt_auth_backend" "oidc" {
  description                   = "OIDC auth via shared Dex (sso.levizitting.com)"
  path                          = "oidc"
  type                          = "oidc"
  oidc_discovery_url            = "https://sso.levizitting.com"
  oidc_client_id                = "openbao"
  oidc_client_secret_wo         = ephemeral.aws_ssm_parameter.dex_openbao_client_secret.value
  oidc_client_secret_wo_version = 1
  default_role                  = "admin"
  bound_issuer                  = "https://sso.levizitting.com"
}

resource "vault_jwt_auth_backend_role" "admin" {
  backend    = vault_jwt_auth_backend.oidc.path
  role_name  = "admin"
  role_type  = "oidc"
  user_claim = "email"
  bound_claims = {
    email = "me@levizitting.com"
  }
  token_policies = ["default"]
  oidc_scopes    = ["openid", "profile", "email"]
  allowed_redirect_uris = [
    "https://secrets.levizitting.com/ui/vault/auth/oidc/oidc/callback",
    "https://secrets.levizitting.com/auth/oidc/callback",
  ]
}

locals {
  application_url = "https://tandoor.levizitting.com"

  secret_versions = {
    runtime = 1
    backup  = 1
    oidc    = 1
  }
}

ephemeral "random_password" "runtime_secret_key" {
  length  = 64
  special = false
}

ephemeral "random_password" "restic_password" {
  length  = 40
  special = false
}

data "zitadel_organizations" "default" {
  is_default = true
}

resource "zitadel_project" "tandoor" {
  name                   = "Tandoor"
  org_id                 = one(data.zitadel_organizations.default.ids)
  project_role_assertion = false
  project_role_check     = true
  has_project_check      = false
}

resource "zitadel_project_role" "access" {
  org_id       = one(data.zitadel_organizations.default.ids)
  project_id   = zitadel_project.tandoor.id
  role_key     = "access"
  display_name = "Tandoor Access"
  group        = "Tandoor"
}

resource "zitadel_application_oidc" "tandoor" {
  project_id = zitadel_project.tandoor.id
  org_id     = one(data.zitadel_organizations.default.ids)

  name                        = "Tandoor"
  redirect_uris               = ["${local.application_url}/accounts/oidc/zitadel/login/callback/"]
  access_token_role_assertion = false
  additional_origins          = []
  response_types = [
    "OIDC_RESPONSE_TYPE_CODE",
  ]
  grant_types = [
    "OIDC_GRANT_TYPE_AUTHORIZATION_CODE",
  ]
  post_logout_redirect_uris    = [local.application_url]
  app_type                     = "OIDC_APP_TYPE_WEB"
  auth_method_type             = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                      = "OIDC_VERSION_1_0"
  dev_mode                     = false
  id_token_role_assertion      = false
  id_token_userinfo_assertion  = false
  skip_native_app_success_page = false
}

resource "vault_kv_secret_v2" "oidc" {
  mount        = var.applications_mount_path
  name         = "tandoor/oidc"
  disable_read = true
  data_json_wo = jsonencode({
    clientId     = zitadel_application_oidc.tandoor.client_id
    clientSecret = zitadel_application_oidc.tandoor.client_secret
    discoveryUrl = "https://${var.zitadel_domain}/.well-known/openid-configuration"
  })
  data_json_wo_version = local.secret_versions.oidc
}

resource "vault_kv_secret_v2" "runtime" {
  mount        = var.applications_mount_path
  name         = "tandoor/runtime"
  disable_read = true
  data_json_wo = jsonencode({
    secretKey = ephemeral.random_password.runtime_secret_key.result
  })
  data_json_wo_version = local.secret_versions.runtime
}

resource "vault_kv_secret_v2" "backup" {
  mount        = var.applications_mount_path
  name         = "tandoor/backup"
  disable_read = true
  data_json_wo = jsonencode({
    resticPassword = ephemeral.random_password.restic_password.result
  })
  data_json_wo_version = local.secret_versions.backup
}

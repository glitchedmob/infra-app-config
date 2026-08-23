locals {
  application_url = "https://tandoor.levizitting.com"

  secret_versions = {
    runtime = 1
    backup  = 1
    oidc    = 1
  }

  bootstrap_oidc_client_secret = false
  rotate_oidc_client_secret    = false
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

resource "vault_policy" "secrets" {
  name   = "tandoor-secrets"
  policy = <<-EOT
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }

    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    path "${var.applications_mount_path}/data/tandoor/*" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "secrets" {
  backend                          = var.kubernetes_auth_path
  role_name                        = "tandoor-secrets"
  bound_service_account_names      = ["tandoor-secrets"]
  bound_service_account_namespaces = ["tandoor"]
  token_policies                   = [vault_policy.secrets.name]
  token_no_default_policy          = true
  token_ttl                        = 900
  token_max_ttl                    = 900
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
  auth_method_type             = local.bootstrap_oidc_client_secret ? "OIDC_AUTH_METHOD_TYPE_NONE" : "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                      = "OIDC_VERSION_1_0"
  dev_mode                     = false
  id_token_role_assertion      = false
  id_token_userinfo_assertion  = false
  skip_native_app_success_page = false
}

ephemeral "zitadel_application_oidc_client_secret" "tandoor" {
  count = local.bootstrap_oidc_client_secret || local.rotate_oidc_client_secret ? 1 : 0

  project_id = zitadel_application_oidc.tandoor.project_id
  app_id     = zitadel_application_oidc.tandoor.id
  org_id     = zitadel_application_oidc.tandoor.org_id
}

resource "vault_kv_secret_v2" "oidc" {
  mount        = var.applications_mount_path
  name         = "tandoor/oidc"
  disable_read = true
  data_json_wo = jsonencode({
    clientId     = zitadel_application_oidc.tandoor.client_id
    clientSecret = one(ephemeral.zitadel_application_oidc_client_secret.tandoor[*].client_secret)
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

locals {
  application_url = "https://mcp.levizitting.com"

  secret_versions = {
    runtime = 1
    backup  = 1
    oidc    = 1
  }

  bootstrap_oidc_client_secret = true
  rotate_oidc_client_secret    = false
}

ephemeral "random_password" "jwt_secret" {
  length  = 64
  special = false
}

ephemeral "random_password" "better_auth_secret" {
  length  = 64
  special = false
}

ephemeral "random_bytes" "credential_encryption_key" {
  length = 32
}

ephemeral "random_password" "admin_password" {
  length  = 40
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
  name   = "mcphub-secrets"
  policy = <<-EOT
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }

    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    path "${var.applications_mount_path}/data/mcphub/*" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "secrets" {
  backend                          = var.kubernetes_auth_path
  role_name                        = "mcphub-secrets"
  bound_service_account_names      = ["mcphub-secrets"]
  bound_service_account_namespaces = ["mcphub"]
  token_policies                   = [vault_policy.secrets.name]
  token_no_default_policy          = true
  token_ttl                        = 900
  token_max_ttl                    = 900
}

resource "zitadel_project" "mcphub" {
  name                   = "MCPHub"
  org_id                 = one(data.zitadel_organizations.default.ids)
  project_role_assertion = false
  project_role_check     = true
  has_project_check      = false
}

resource "zitadel_project_role" "access" {
  org_id       = one(data.zitadel_organizations.default.ids)
  project_id   = zitadel_project.mcphub.id
  role_key     = "access"
  display_name = "MCPHub Access"
  group        = "MCPHub"
}

resource "zitadel_application_oidc" "mcphub" {
  project_id = zitadel_project.mcphub.id
  org_id     = one(data.zitadel_organizations.default.ids)

  name                      = "MCPHub"
  redirect_uris             = ["${local.application_url}/api/auth/better/oauth2/callback/zitadel"]
  response_types            = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types               = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  post_logout_redirect_uris = [local.application_url]
  app_type                  = "OIDC_APP_TYPE_WEB"
  # NONE avoids persisting a creation-time secret in the ZITADEL resource state.
  auth_method_type             = local.bootstrap_oidc_client_secret ? "OIDC_AUTH_METHOD_TYPE_NONE" : "OIDC_AUTH_METHOD_TYPE_POST"
  version                      = "OIDC_VERSION_1_0"
  dev_mode                     = false
  access_token_role_assertion  = false
  id_token_role_assertion      = false
  id_token_userinfo_assertion  = false
  additional_origins           = []
  skip_native_app_success_page = false

}

ephemeral "zitadel_application_oidc_client_secret" "mcphub" {
  count = local.bootstrap_oidc_client_secret || local.rotate_oidc_client_secret ? 1 : 0

  project_id = zitadel_application_oidc.mcphub.project_id
  app_id     = zitadel_application_oidc.mcphub.id
  org_id     = zitadel_application_oidc.mcphub.org_id
}

resource "vault_kv_secret_v2" "oidc" {
  mount        = var.applications_mount_path
  name         = "mcphub/oidc"
  disable_read = true
  data_json_wo = jsonencode({
    providerId   = "zitadel"
    clientId     = zitadel_application_oidc.mcphub.client_id
    clientSecret = one(ephemeral.zitadel_application_oidc_client_secret.mcphub[*].client_secret)
    issuerUrl    = "https://${var.zitadel_domain}"
  })
  data_json_wo_version = local.secret_versions.oidc
}

resource "vault_kv_secret_v2" "runtime" {
  mount        = var.applications_mount_path
  name         = "mcphub/runtime"
  disable_read = true
  data_json_wo = jsonencode({
    jwtSecret               = ephemeral.random_password.jwt_secret.result
    betterAuthSecret        = ephemeral.random_password.better_auth_secret.result
    credentialEncryptionKey = ephemeral.random_bytes.credential_encryption_key.base64
    adminPassword           = ephemeral.random_password.admin_password.result
  })
  data_json_wo_version = local.secret_versions.runtime
}

resource "vault_kv_secret_v2" "backup" {
  mount        = var.applications_mount_path
  name         = "mcphub/backup"
  disable_read = true
  data_json_wo = jsonencode({
    resticPassword = ephemeral.random_password.restic_password.result
  })
  data_json_wo_version = local.secret_versions.backup
}

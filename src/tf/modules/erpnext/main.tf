locals {
  application_url = "https://finances.levizitting.com"

  secret_versions = {
    runtime  = 1
    database = 1
    backup   = 1
    oidc     = 1
  }

  bootstrap_oidc_client_secret = true
  rotate_oidc_client_secret    = false
}

ephemeral "random_password" "admin_password" {
  length  = 40
  special = false
}

ephemeral "random_bytes" "encryption_key" {
  length = 32
}

ephemeral "random_password" "database_root_password" {
  length  = 40
  special = false
}

ephemeral "random_password" "database_password" {
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
  name   = "erpnext-secrets"
  policy = <<-EOT
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }

    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    path "${var.applications_mount_path}/data/erpnext/*" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "secrets" {
  backend                          = var.kubernetes_auth_path
  role_name                        = "erpnext-secrets"
  bound_service_account_names      = ["erpnext-secrets"]
  bound_service_account_namespaces = ["erpnext"]
  token_policies                   = [vault_policy.secrets.name]
  token_no_default_policy          = true
  token_ttl                        = 900
  token_max_ttl                    = 900
}

resource "zitadel_project" "erpnext" {
  name                   = "ERPNext"
  org_id                 = one(data.zitadel_organizations.default.ids)
  project_role_assertion = false
  project_role_check     = true
  has_project_check      = false
}

resource "zitadel_project_role" "access" {
  org_id       = one(data.zitadel_organizations.default.ids)
  project_id   = zitadel_project.erpnext.id
  role_key     = "access"
  display_name = "ERPNext Access"
  group        = "ERPNext"
}

resource "zitadel_application_oidc" "erpnext" {
  project_id = zitadel_project.erpnext.id
  org_id     = one(data.zitadel_organizations.default.ids)

  name                        = "ERPNext"
  redirect_uris               = ["${local.application_url}/api/method/frappe.integrations.oauth2_logins.custom/zitadel"]
  access_token_role_assertion = false
  additional_origins          = []
  response_types = [
    "OIDC_RESPONSE_TYPE_CODE",
  ]
  grant_types = [
    "OIDC_GRANT_TYPE_AUTHORIZATION_CODE",
  ]
  post_logout_redirect_uris = [local.application_url]
  app_type                  = "OIDC_APP_TYPE_WEB"
  # Creating with NONE avoids a creation-time client secret in state.
  auth_method_type             = local.bootstrap_oidc_client_secret ? "OIDC_AUTH_METHOD_TYPE_NONE" : "OIDC_AUTH_METHOD_TYPE_POST"
  version                      = "OIDC_VERSION_1_0"
  dev_mode                     = false
  id_token_role_assertion      = false
  id_token_userinfo_assertion  = false
  skip_native_app_success_page = false
}

ephemeral "zitadel_application_oidc_client_secret" "erpnext" {
  # Bootstrap generates once after client creation; steady state disables this.
  count = local.bootstrap_oidc_client_secret || local.rotate_oidc_client_secret ? 1 : 0

  project_id = zitadel_application_oidc.erpnext.project_id
  app_id     = zitadel_application_oidc.erpnext.id
  org_id     = zitadel_application_oidc.erpnext.org_id

  depends_on = [zitadel_application_oidc.erpnext]
}

resource "vault_kv_secret_v2" "oidc" {
  mount        = var.applications_mount_path
  name         = "erpnext/oidc"
  disable_read = true
  data_json_wo = jsonencode({
    clientId     = zitadel_application_oidc.erpnext.client_id
    clientSecret = one(ephemeral.zitadel_application_oidc_client_secret.erpnext[*].client_secret)
    issuerUrl    = "https://${var.zitadel_domain}"
  })
  data_json_wo_version = local.secret_versions.oidc
}

resource "vault_kv_secret_v2" "runtime" {
  mount        = var.applications_mount_path
  name         = "erpnext/runtime"
  disable_read = true
  data_json_wo = jsonencode({
    adminPassword = ephemeral.random_password.admin_password.result
    # Fernet requires URL-safe base64 of exactly 32 bytes, including padding.
    encryptionKey = replace(replace(ephemeral.random_bytes.encryption_key.base64, "+", "-"), "/", "_")
  })
  data_json_wo_version = local.secret_versions.runtime
}

resource "vault_kv_secret_v2" "database" {
  mount        = var.applications_mount_path
  name         = "erpnext/database"
  disable_read = true
  data_json_wo = jsonencode({
    rootPassword = ephemeral.random_password.database_root_password.result
    password     = ephemeral.random_password.database_password.result
  })
  data_json_wo_version = local.secret_versions.database
}

resource "vault_kv_secret_v2" "backup" {
  mount        = var.applications_mount_path
  name         = "erpnext/backup"
  disable_read = true
  data_json_wo = jsonencode({
    resticPassword = ephemeral.random_password.restic_password.result
  })
  data_json_wo_version = local.secret_versions.backup
}

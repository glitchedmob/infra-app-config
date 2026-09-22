locals {
  application_url = "https://speedtest.levizitting.com"
  secret_versions = {
    app_key        = 1
    admin_password = 1
    cookie_secret  = 1
    oidc           = 1
    backup         = 1
  }

  # Set this to false after the first apply creates and stores the client secret.
  bootstrap_oidc_client_secret = false
  rotate_oidc_client_secret    = false
}

data "zitadel_organizations" "default" {
  is_default = true
}

data "zitadel_human_users" "levi" {
  org_id       = one(data.zitadel_organizations.default.ids)
  email        = "me@levizitting.com"
  email_method = "TEXT_QUERY_METHOD_EQUALS_IGNORE_CASE"
}

resource "zitadel_project" "isp_monitoring" {
  name                   = "ISP Monitoring"
  org_id                 = one(data.zitadel_organizations.default.ids)
  project_role_assertion = false
  project_role_check     = true
  has_project_check      = false
}

resource "zitadel_project_role" "access" {
  org_id       = zitadel_project.isp_monitoring.org_id
  project_id   = zitadel_project.isp_monitoring.id
  role_key     = "access"
  display_name = "ISP Monitoring Access"
  group        = "ISP Monitoring"
}

resource "zitadel_user_grant" "levi" {
  org_id     = zitadel_project.isp_monitoring.org_id
  project_id = zitadel_project.isp_monitoring.id
  user_id    = one(data.zitadel_human_users.levi.user_ids)
  role_keys  = [zitadel_project_role.access.role_key]
}

resource "zitadel_application_oidc" "isp_monitoring" {
  project_id = zitadel_project.isp_monitoring.id
  org_id     = zitadel_project.isp_monitoring.org_id
  name       = "ISP Monitoring"

  redirect_uris                = ["${local.application_url}/oauth2/callback"]
  response_types               = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                  = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  post_logout_redirect_uris    = [local.application_url]
  app_type                     = "OIDC_APP_TYPE_WEB"
  auth_method_type             = local.bootstrap_oidc_client_secret ? "OIDC_AUTH_METHOD_TYPE_NONE" : "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                      = "OIDC_VERSION_1_0"
  dev_mode                     = false
  access_token_role_assertion  = false
  id_token_role_assertion      = false
  id_token_userinfo_assertion  = true
  skip_native_app_success_page = false
  additional_origins           = []
}

ephemeral "zitadel_application_oidc_client_secret" "isp_monitoring" {
  count = local.bootstrap_oidc_client_secret || local.rotate_oidc_client_secret ? 1 : 0

  project_id = zitadel_application_oidc.isp_monitoring.project_id
  app_id     = zitadel_application_oidc.isp_monitoring.id
  org_id     = zitadel_application_oidc.isp_monitoring.org_id
}

resource "vault_policy" "secrets" {
  name   = "isp-monitoring-secrets"
  policy = <<-EOT
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }
    path "auth/token/renew-self" {
      capabilities = ["update"]
    }
    path "${var.applications_mount_path}/data/isp-monitoring/*" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "secrets" {
  backend                          = var.kubernetes_auth_path
  role_name                        = "isp-monitoring-secrets"
  bound_service_account_names      = ["isp-monitoring-secrets"]
  bound_service_account_namespaces = ["isp-monitoring"]
  token_policies                   = [vault_policy.secrets.name]
  token_no_default_policy          = true
  token_ttl                        = 900
  token_max_ttl                    = 900
}

ephemeral "random_password" "app_key" {
  length  = 32
  special = false
}

ephemeral "random_password" "admin_password" {
  length  = 40
  special = false
}

ephemeral "random_password" "cookie_secret" {
  length  = 32
  special = false
}

ephemeral "random_password" "restic_password" {
  length  = 40
  special = false
}

resource "vault_kv_secret_v2" "app_key" {
  mount        = var.applications_mount_path
  name         = "isp-monitoring/app-key"
  disable_read = true
  data_json_wo = jsonencode({
    appKey = "base64:${base64encode(ephemeral.random_password.app_key.result)}"
  })
  data_json_wo_version = local.secret_versions.app_key
}

resource "vault_kv_secret_v2" "admin_password" {
  mount        = var.applications_mount_path
  name         = "isp-monitoring/admin-password"
  disable_read = true
  data_json_wo = jsonencode({
    adminPassword = ephemeral.random_password.admin_password.result
  })
  data_json_wo_version = local.secret_versions.admin_password
}

resource "vault_kv_secret_v2" "oidc" {
  mount        = var.applications_mount_path
  name         = "isp-monitoring/oidc"
  disable_read = true
  data_json_wo = jsonencode({
    clientId     = zitadel_application_oidc.isp_monitoring.client_id
    clientSecret = one(ephemeral.zitadel_application_oidc_client_secret.isp_monitoring[*].client_secret)
    issuerUrl    = "https://${var.zitadel_domain}"
  })
  data_json_wo_version = local.secret_versions.oidc
}

resource "vault_kv_secret_v2" "cookie_secret" {
  mount        = var.applications_mount_path
  name         = "isp-monitoring/cookie-secret"
  disable_read = true
  data_json_wo = jsonencode({
    cookieSecret = base64encode(ephemeral.random_password.cookie_secret.result)
  })
  data_json_wo_version = local.secret_versions.cookie_secret
}

resource "vault_kv_secret_v2" "backup" {
  mount        = var.applications_mount_path
  name         = "isp-monitoring/backup"
  disable_read = true
  data_json_wo = jsonencode({
    resticPassword = ephemeral.random_password.restic_password.result
  })
  data_json_wo_version = local.secret_versions.backup
}

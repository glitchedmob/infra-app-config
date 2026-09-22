locals {
  secret_versions = {
    app_key        = 1
    admin_password = 1
    backup         = 1
  }
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

resource "vault_kv_secret_v2" "backup" {
  mount        = var.applications_mount_path
  name         = "isp-monitoring/backup"
  disable_read = true
  data_json_wo = jsonencode({
    resticPassword = ephemeral.random_password.restic_password.result
  })
  data_json_wo_version = local.secret_versions.backup
}

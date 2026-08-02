locals {
  secret_versions = {
    runtime = 1
    backup  = 1
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

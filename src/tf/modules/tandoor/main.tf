locals {
  secret_versions = {
    backup = 1
  }
}

ephemeral "random_password" "restic_password" {
  length  = 40
  special = false
}

# Keep the password for the retained Backblaze repository after retiring Tandoor.
resource "vault_kv_secret_v2" "backup" {
  mount        = var.applications_mount_path
  name         = "tandoor/backup"
  disable_read = true
  data_json_wo = jsonencode({
    resticPassword = ephemeral.random_password.restic_password.result
  })
  data_json_wo_version = local.secret_versions.backup

  lifecycle {
    prevent_destroy = true
  }
}

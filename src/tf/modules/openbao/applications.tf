resource "vault_mount" "applications" {
  path = "applications"
  type = "kv"

  options = {
    version = "2"
  }
}

resource "vault_policy" "application_secrets_admin" {
  name   = "application-secrets-admin"
  policy = <<-EOT
    path "${vault_mount.applications.path}/*" {
      capabilities = ["create", "read", "update", "patch", "delete", "list"]
    }
  EOT
}

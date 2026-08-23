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
resource "vault_policy" "sparky_secrets" {
  name   = "sparky-secrets"
  policy = <<-EOT
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }

    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    path "${vault_mount.applications.path}/data/sparky/*" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "sparky_secrets" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "sparky-secrets"
  bound_service_account_names      = ["sparky-secrets"]
  bound_service_account_namespaces = ["sparky"]
  token_policies                   = [vault_policy.sparky_secrets.name]
  token_no_default_policy          = true
  token_ttl                        = 900
  token_max_ttl                    = 900
}

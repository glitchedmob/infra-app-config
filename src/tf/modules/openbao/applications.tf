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

resource "vault_policy" "tandoor_secrets" {
  name   = "tandoor-secrets"
  policy = <<-EOT
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }

    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    path "${vault_mount.applications.path}/data/tandoor/*" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "tandoor_secrets" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "tandoor-secrets"
  bound_service_account_names      = ["tandoor-secrets"]
  bound_service_account_namespaces = ["tandoor"]
  token_policies                   = [vault_policy.tandoor_secrets.name]
  token_no_default_policy          = true
  token_ttl                        = 900
  token_max_ttl                    = 900
}

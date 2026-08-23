moved {
  from = module.openbao.vault_policy.tandoor_secrets
  to   = module.tandoor.vault_policy.secrets
}

moved {
  from = module.openbao.vault_kubernetes_auth_backend_role.tandoor_secrets
  to   = module.tandoor.vault_kubernetes_auth_backend_role.secrets
}

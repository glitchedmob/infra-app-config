output "applications_mount_path" {
  description = "Path of the shared application secrets KV mount"
  value       = vault_mount.applications.path
}

output "kubernetes_auth_path" {
  description = "Path of the Kubernetes authentication backend"
  value       = vault_auth_backend.kubernetes.path
}

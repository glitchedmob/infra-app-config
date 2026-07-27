output "applications_mount_path" {
  description = "Path of the shared application secrets KV mount"
  value       = vault_mount.applications.path
}

variable "applications_mount_path" {
  description = "Path of the shared OpenBao application secrets mount"
  type        = string
}

variable "kubernetes_auth_path" {
  description = "Path of the OpenBao Kubernetes authentication backend"
  type        = string
}

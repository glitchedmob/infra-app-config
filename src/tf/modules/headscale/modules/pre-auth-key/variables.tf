variable "user_id" {
  description = "Headscale user ID that owns the pre-auth key."
  type        = string
}

variable "time_to_expire" {
  description = "Pre-auth key TTL duration (for example 1h, 90d)."
  type        = string
}

variable "reusable" {
  description = "Whether the pre-auth key is reusable."
  type        = bool
}

variable "ephemeral" {
  description = "Whether devices enrolled with this key are ephemeral."
  type        = bool
}

variable "acl_tags" {
  description = "ACL tags to apply to this pre-auth key."
  type        = list(string)
  default     = []
}

variable "ssm_parameter_name" {
  description = "SSM parameter path where the generated pre-auth key is stored."
  type        = string
}

variable "ssm_parameter_description" {
  description = "Description for the SSM parameter containing the pre-auth key."
  type        = string
}

variable "auth_key_rotation_version" {
  description = "Rotation version used to trigger key regeneration and SSM write-only updates."
  type        = number
}

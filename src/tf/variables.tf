variable "aws_region" {
  description = "AWS region for SSM parameters"
  type        = string
  default     = "us-east-2"
}

variable "headscale_host" {
  description = "Headscale hostname"
  type        = string
  default     = "headscale.levizitting.com"
}

variable "headscale_api_key" {
  description = "Headscale API key"
  type        = string
  sensitive   = true
}

variable "uptimekuma_endpoint" {
  description = "Uptime Kuma endpoint URL"
  type        = string
  default     = "https://uptime.levizitting.com"
}

variable "uptimekuma_username" {
  description = "Uptime Kuma username"
  type        = string
  sensitive   = true
}

variable "uptimekuma_password" {
  description = "Uptime Kuma password"
  type        = string
  sensitive   = true
}

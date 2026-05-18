locals {
  email_alert_id = 1
}

resource "uptimekuma_monitor_group" "proxmox" {
  name   = "Proxmox Nodes"
  active = true
}

resource "uptimekuma_monitor_push" "proxmox" {
  for_each = toset(local.headscale_proxmox_nodes)

  name             = "Proxmox ${each.key}"
  parent           = uptimekuma_monitor_group.proxmox.id
  interval         = 60
  active           = true
  notification_ids = [local.email_alert_id]
}

resource "aws_ssm_parameter" "proxmox_monitor_push_url" {
  for_each = uptimekuma_monitor_push.proxmox

  name             = "/homelab/monitor/proxmox/${each.key}-monitor-push-url"
  type             = "SecureString"
  description      = "Monitor push heartbeat URL for ${each.key}"
  value_wo         = "${var.uptimekuma_endpoint}/api/push/${each.value.push_token}?status=up"
  value_wo_version = 1
  overwrite        = true
}
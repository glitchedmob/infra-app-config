locals {
  email_alert_id = 1

  netlify_site_monitors = {
    "www.levizitting.com"    = "https://www.levizitting.com"
    "www.melissaworthen.com" = "https://www.melissaworthen.com"
    "www.opensgf.org"        = "https://www.opensgf.org"
  }

  legacy_server_monitors = {
    "bighead.levizitting.com"   = "bighead.levizitting.com cron"
    "middleout.levizitting.com" = "middleout.levizitting.com cron"
    "nothotdog.levizitting.com" = "nothotdog.levizitting.com cron"
  }

  legacy_service_monitors = {
    "cms.methodconf.com"    = "https://cms.methodconf.com"
    "crm.sgf.dev"           = "https://crm.sgf.dev"
    "docs.opensgf.org"      = "https://docs.opensgf.org"
    "docs.sgf.dev"          = "https://docs.sgf.dev"
    "grocy.levizitting.com" = "https://grocy.levizitting.com"
    "methodconf.com"        = "https://methodconf.com"
    "newsletter.sgf.dev"    = "https://newsletter.sgf.dev"
    "plane.sgf.dev"         = "https://plane.sgf.dev"
    "social.sgf.dev"        = "https://social.sgf.dev"
    "www.sgf.dev"           = "https://www.sgf.dev"
  }
}

resource "uptimekuma_monitor_group" "proxmox" {
  name   = "Proxmox Nodes"
  active = true
}

resource "uptimekuma_monitor_group" "netlify_sites" {
  name   = "Netlify sites"
  active = true
}

resource "uptimekuma_monitor_group" "legacy_servers" {
  name   = "Legacy servers"
  active = true
}

resource "uptimekuma_monitor_group" "legacy_services" {
  name   = "Legacy services"
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

resource "uptimekuma_monitor_http" "netlify_sites" {
  for_each = local.netlify_site_monitors

  name             = each.key
  url              = each.value
  parent           = uptimekuma_monitor_group.netlify_sites.id
  interval         = 60
  active           = true
  notification_ids = [local.email_alert_id]
}

resource "uptimekuma_monitor_push" "legacy_servers" {
  for_each = local.legacy_server_monitors

  name             = each.value
  parent           = uptimekuma_monitor_group.legacy_servers.id
  interval         = 60
  active           = true
  notification_ids = [local.email_alert_id]
}

resource "uptimekuma_monitor_http" "legacy_services" {
  for_each = local.legacy_service_monitors

  name             = each.key
  url              = each.value
  parent           = uptimekuma_monitor_group.legacy_services.id
  interval         = 60
  timeout          = 48
  max_retries      = 2
  retry_interval   = 60
  resend_interval  = 0
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

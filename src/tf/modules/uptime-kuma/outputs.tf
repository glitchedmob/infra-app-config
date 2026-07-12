output "ssm_paths" {
  value = {
    uptime_kuma_proxmox_monitor_push_urls = {
      for node_name, param in aws_ssm_parameter.proxmox_monitor_push_url :
      node_name => param.name
    }
  }
}

output "headscale_proxmox_auth_key_ssm_paths" {
  value = {
    for node_name, key_module in module.headscale_proxmox_auth_keys :
    node_name => key_module.ssm_parameter_name
  }
  description = "SSM parameter paths for per-node Headscale pre-auth keys"
}

output "headscale_gha_lz_auth_key_ssm_path" {
  value       = module.headscale_gha_lz_auth_key.ssm_parameter_name
  description = "SSM parameter path for lz GitHub Actions Headscale pre-auth key"
}

output "headscale_gha_sgfdevs_auth_key_ssm_path" {
  value       = module.headscale_gha_sgfdevs_auth_key.ssm_parameter_name
  description = "SSM parameter path for sgfdevs GitHub Actions Headscale pre-auth key"
}

output "headscale_infra_public_edge_auth_key_ssm_path" {
  value       = module.headscale_infra_public_edge_auth_key.ssm_parameter_name
  description = "SSM parameter path for infra-public-edge Headscale pre-auth key"
}

output "proxmox_monitor_push_url_ssm_paths" {
  value = {
    for node_name, param in aws_ssm_parameter.proxmox_monitor_push_url :
    node_name => param.name
  }
  description = "SSM parameter paths for per-node monitor push heartbeat URLs"
}

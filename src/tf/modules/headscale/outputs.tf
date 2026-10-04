output "ssm_paths" {
  value = {
    headscale_proxmox_auth_keys = {
      for node_name, key_module in module.headscale_proxmox_auth_keys :
      node_name => key_module.ssm_parameter_name
    }
    headscale_gha_lz_auth_key                  = module.headscale_gha_lz_auth_key.ssm_parameter_name
    headscale_gha_sgfdevs_auth_key             = module.headscale_gha_sgfdevs_auth_key.ssm_parameter_name
    headscale_infra_public_edge_auth_key       = module.headscale_infra_public_edge_auth_key.ssm_parameter_name
    headscale_mastodon_auth_key                = module.headscale_mastodon_auth_key.ssm_parameter_name
    headscale_lz_dns_gateway_auth_key          = module.headscale_lz_dns_gateway_auth_key.ssm_parameter_name
    headscale_lz_ingress_gateway_auth_key      = module.headscale_lz_ingress_gateway_auth_key.ssm_parameter_name
    headscale_sgfdevs_ingress_gateway_auth_key = module.headscale_sgfdevs_ingress_gateway_auth_key.ssm_parameter_name
  }
}

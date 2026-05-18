module "headscale_proxmox_auth_keys" {
  for_each = toset(local.headscale_proxmox_nodes)
  source   = "./modules/headscale-pre-auth-key"

  user_id                   = headscale_user.proxmox.id
  time_to_expire            = "1h"
  reusable                  = false
  ephemeral                 = false
  acl_tags                  = [local.proxmox_tag]
  ssm_parameter_name        = "/homelab/headscale/proxmox/${each.key}-auth-key"
  ssm_parameter_description = "Headscale pre-auth key for ${each.key}"
  auth_key_rotation_version = 1
}

module "headscale_gha_lz_auth_key" {
  source = "./modules/headscale-pre-auth-key"

  user_id                   = headscale_user.gha_lz.id
  time_to_expire            = "36500d"
  reusable                  = true
  ephemeral                 = true
  acl_tags                  = [local.gha_lz_tag]
  ssm_parameter_name        = "/homelab/headscale/gha/lz-auth-key"
  ssm_parameter_description = "Headscale pre-auth key for lz GitHub Actions"
  auth_key_rotation_version = 1
}

module "headscale_gha_sgfdevs_auth_key" {
  source = "./modules/headscale-pre-auth-key"

  user_id                   = headscale_user.gha_sgfdevs.id
  time_to_expire            = "36500d"
  reusable                  = true
  ephemeral                 = true
  acl_tags                  = [local.gha_sgfdevs_tag]
  ssm_parameter_name        = "/homelab/headscale/gha/sgfdevs-auth-key"
  ssm_parameter_description = "Headscale pre-auth key for sgfdevs GitHub Actions"
  auth_key_rotation_version = 7
}

module "headscale_infra_public_edge_auth_key" {
  source = "./modules/headscale-pre-auth-key"

  user_id                   = headscale_user.infra_public_edge.id
  time_to_expire            = "1h"
  reusable                  = false
  ephemeral                 = false
  acl_tags                  = [local.infra_public_edge_tag]
  ssm_parameter_name        = "/homelab/headscale/infra-public-edge/${local.infra_public_edge_node}-auth-key"
  ssm_parameter_description = "Headscale pre-auth key for ${local.infra_public_edge_node}"
  auth_key_rotation_version = 1
}

module "headscale" {
  source = "./modules/headscale"
}

module "uptime_kuma" {
  source = "./modules/uptime-kuma"

  uptimekuma_endpoint = var.uptimekuma_endpoint
  proxmox_nodes       = ["x86-node-01", "x86-node-02"]
}

module "openbao" {
  source = "./modules/openbao"
}

module "tandoor" {
  source = "./modules/tandoor"

  applications_mount_path = module.openbao.applications_mount_path
  zitadel_domain          = var.zitadel_domain
}

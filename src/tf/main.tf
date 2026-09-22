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

module "zitadel" {
  source = "./modules/zitadel"
}

module "tandoor" {
  source = "./modules/tandoor"

  applications_mount_path = module.openbao.applications_mount_path
  kubernetes_auth_path    = module.openbao.kubernetes_auth_path
  zitadel_domain          = var.zitadel_domain
}

module "isp_monitoring" {
  source = "./modules/isp-monitoring"

  applications_mount_path = module.openbao.applications_mount_path
  kubernetes_auth_path    = module.openbao.kubernetes_auth_path
  zitadel_domain          = var.zitadel_domain
}

module "sparky" {
  source = "./modules/sparky"

  applications_mount_path = module.openbao.applications_mount_path
  kubernetes_auth_path    = module.openbao.kubernetes_auth_path
  zitadel_domain          = var.zitadel_domain
}

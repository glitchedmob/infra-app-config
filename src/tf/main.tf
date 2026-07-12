module "headscale" {
  source = "./modules/headscale"
}

module "uptime_kuma" {
  source = "./modules/uptime-kuma"

  uptimekuma_endpoint = var.uptimekuma_endpoint
  proxmox_nodes       = ["x86-node-01", "x86-node-02"]
}

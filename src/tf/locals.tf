locals {
  management_route        = "10.0.0.0/24"
  workload_route_supernet = "10.20.0.0/16"
  lz_workload_cidr        = "10.20.0.0/22"
  sgfdevs_workload_cidr   = "10.20.4.0/22"
  proxmox_tag             = "tag:proxmox-x86"
  infra_public_edge_tag   = "tag:infra-public-edge"
  gha_lz_tag              = "tag:gha-lz"
  gha_sgfdevs_tag         = "tag:gha-sgfdevs"
  lz_k3s_tag              = "tag:lz-k3s"
  proxmox_user            = "proxmox"
  infra_public_edge_user  = "infra-public-edge"
  gha_lz_user             = "gha-lz"
  gha_sgfdevs_user        = "gha-sgfdevs"
  lz_k3s_user             = "lz-k3s"
  infra_public_edge_node  = "x86-vps-node-01"
  public_edge_dns_ip      = "10.255.255.1/32"
  admins                  = [headscale_user.levizitting.name]
  headscale_proxmox_nodes = ["x86-node-01", "x86-node-02"]
  headscale_lz_k3s_nodes  = ["lz-k3s-01", "lz-k3s-02"]
}

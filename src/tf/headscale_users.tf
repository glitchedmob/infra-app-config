resource "headscale_user" "levizitting" {
  name         = "levizitting"
  display_name = "Levi Zitting"
  email        = "me@levizitting.com"
  force_delete = true
}

resource "headscale_user" "proxmox" {
  name         = "proxmox"
  force_delete = true
}

resource "headscale_user" "infra_public_edge" {
  name         = local.infra_public_edge_user
  force_delete = true
}

resource "headscale_user" "gha_lz" {
  name         = local.gha_lz_user
  force_delete = true
}

resource "headscale_user" "gha_sgfdevs" {
  name         = local.gha_sgfdevs_user
  force_delete = true
}

resource "headscale_policy" "this" {
  policy = jsonencode({
    "groups" : {
      "group:admins" : formatlist("%s@", local.admins)
      "group:infra" : concat(
        formatlist("%s@", local.admins),
        [format("%s@", local.proxmox_user)]
      )
    }
    "tagOwners" : {
      (local.proxmox_tag) : ["group:infra"]
      (local.infra_public_edge_tag) : ["group:infra"]
      (local.gha_lz_tag) : ["group:infra"]
      (local.gha_sgfdevs_tag) : ["group:infra"]
      (local.lz_k3s_tag) : ["group:infra"]
    }
    "autoApprovers" : {
      "routes" : {
        (local.management_route) : [local.proxmox_tag]
        (local.workload_route_supernet) : [local.proxmox_tag]
        (local.public_edge_dns_ip) : [local.infra_public_edge_tag, local.proxmox_tag, local.lz_k3s_tag]
      }
    }
    "acls" : [
      {
        "action" : "accept"
        "src" : ["group:admins"]
        "dst" : [
          format("%s:*", local.proxmox_tag),
          format("%s:*", local.infra_public_edge_tag),
          format("%s:*", local.management_route),
          format("%s:*", local.workload_route_supernet),
        ]
      },
      {
        "action" : "accept"
        "src" : [local.proxmox_tag]
        "dst" : [format("%s:*", local.proxmox_tag)]
      },
      {
        "action" : "accept"
        "src" : [local.infra_public_edge_tag]
        "dst" : [format("%s:80", local.lz_workload_cidr)]
      },
      {
        "action" : "accept"
        "src" : [local.infra_public_edge_tag]
        "dst" : [format("%s:443", local.lz_workload_cidr)]
      },
      {
        "action" : "accept"
        "src" : [local.infra_public_edge_tag]
        "dst" : [format("%s:80", local.sgfdevs_workload_cidr)]
      },
      {
        "action" : "accept"
        "src" : [local.infra_public_edge_tag]
        "dst" : [format("%s:443", local.sgfdevs_workload_cidr)]
      },
      {
        "action" : "accept"
        "src" : [local.infra_public_edge_tag]
        "dst" : [format("%s:80", local.proxmox_tag)]
      },
      {
        "action" : "accept"
        "src" : [local.infra_public_edge_tag]
        "dst" : [format("%s:443", local.proxmox_tag)]
      },
      {
        "action" : "accept"
        "src" : [local.gha_lz_tag]
        "dst" : [format("%s:8006", local.proxmox_tag)]
      },
      {
        "action" : "accept"
        "src" : [local.gha_lz_tag]
        "dst" : [format("%s:22", local.lz_workload_cidr)]
      },
      {
        "action" : "accept"
        "src" : [local.gha_lz_tag]
        "dst" : [format("%s:22", local.infra_public_edge_tag)]
      },
      {
        "action" : "accept"
        "src" : [local.gha_lz_tag]
        "dst" : [format("%s:443", local.lz_k3s_tag)]
      },
      {
        "action" : "accept"
        "src" : [local.gha_lz_tag]
        "dst" : [format("%s:443", local.lz_workload_cidr)]
      },
      {
        "action" : "accept"
        "proto" : "icmp"
        "src" : [local.gha_lz_tag]
        "dst" : [format("%s:*", local.lz_workload_cidr)]
      },
      {
        "action" : "accept"
        "src" : ["*"]
        "dst" : [format("%s:53", local.public_edge_dns_ip)]
      },
      {
        "action" : "accept"
        "src" : [local.gha_sgfdevs_tag]
        "dst" : [format("%s:8006", local.proxmox_tag)]
      },
      {
        "action" : "accept"
        "src" : [local.gha_sgfdevs_tag]
        "dst" : [format("%s:22", local.sgfdevs_workload_cidr)]
      },
      {
        "action" : "accept"
        "proto" : "icmp"
        "src" : [local.gha_sgfdevs_tag]
        "dst" : [format("%s:*", local.sgfdevs_workload_cidr)]
      },
    ]
  })
}

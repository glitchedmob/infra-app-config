mock_provider "aws" {}
mock_provider "headscale" {
  mock_resource "headscale_user" {
    defaults = {
      id = "1"
    }
  }
}
mock_provider "json-formatter" {}

run "levi_device_access" {
  command = plan

  assert {
    condition = (
      jsondecode(data.json-formatter_format_json.headscale_policy.json).groups["group:levi-devices"] == ["levizitting@"] &&
      !strcontains(data.json-formatter_format_json.headscale_policy.json, "group:admins")
    )
    error_message = "The ownership-based group must contain only Levi and replace all legacy group references."
  }

  assert {
    condition = anytrue([
      for acl in jsondecode(data.json-formatter_format_json.headscale_policy.json).acls :
      acl.action == "accept" && acl.src == ["group:levi-devices"] && acl.dst == ["autogroup:self:*"] && !can(acl.proto)
    ])
    error_message = "Levi's user-owned devices must reach each other on every port and protocol."
  }

  assert {
    condition = alltrue([
      for acl in jsondecode(data.json-formatter_format_json.headscale_policy.json).acls :
      acl.src == ["group:levi-devices"]
      if contains(acl.dst, "autogroup:self:*")
    ])
    error_message = "Other tailnet members must not inherit Levi's unrestricted device access."
  }

  assert {
    condition = anytrue([
      for acl in jsondecode(data.json-formatter_format_json.headscale_policy.json).acls :
      acl.action == "accept" && acl.src == ["group:levi-devices"] && acl.dst == ["autogroup:internet:*"]
    ])
    error_message = "Levi must retain exit-node access."
  }

  assert {
    condition = anytrue([
      for acl in jsondecode(data.json-formatter_format_json.headscale_policy.json).acls :
      acl.action == "accept" && acl.src == ["group:levi-devices"] && acl.dst == [
        "tag:proxmox-x86:*", "tag:infra-public-edge:*", "10.0.0.0/24:*", "10.20.0.0/16:*"
      ]
    ])
    error_message = "Levi must retain the existing infrastructure and subnet access."
  }

  assert {
    condition = (
      jsondecode(data.json-formatter_format_json.headscale_policy.json).groups["group:infra"] == ["levizitting@", "proxmox@"] &&
      alltrue([
        for owners in values(jsondecode(data.json-formatter_format_json.headscale_policy.json).tagOwners) :
        owners == ["group:infra"]
      ])
    )
    error_message = "The rename must preserve infrastructure tag ownership."
  }

  assert {
    condition = jsondecode(data.json-formatter_format_json.headscale_policy.json).ssh == [{
      action = "accept"
      src    = ["group:levi-devices"]
      dst    = ["autogroup:self"]
      users  = ["autogroup:nonroot"]
    }]
    error_message = "The rename must preserve the existing non-root Tailscale SSH permissions."
  }
}

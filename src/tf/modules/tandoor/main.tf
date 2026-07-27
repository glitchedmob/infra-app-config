locals {
  application_slug = "tandoor"
  application_url  = "https://tandoor.levizitting.com"

  secret_versions = {
    runtime = 1
    backup  = 1
  }
}

ephemeral "random_password" "runtime_secret_key" {
  length  = 64
  special = false
}

ephemeral "random_password" "restic_password" {
  length  = 40
  special = false
}

data "authentik_flow" "authentication" {
  slug = "default-authentication-flow"
}

data "authentik_flow" "authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "invalidation" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_property_mapping_provider_scope" "oidc" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

data "authentik_certificate_key_pair" "default" {
  name      = "authentik Self-signed Certificate"
  fetch_key = false
}

resource "authentik_group" "users" {
  name = "tandoor-users"
}

resource "authentik_provider_oauth2" "this" {
  name                = "Tandoor"
  client_id           = local.application_slug
  client_type         = "confidential"
  grant_types         = ["authorization_code"]
  authentication_flow = data.authentik_flow.authentication.id
  authorization_flow  = data.authentik_flow.authorization.id
  invalidation_flow   = data.authentik_flow.invalidation.id
  property_mappings   = data.authentik_property_mapping_provider_scope.oidc.ids
  signing_key         = data.authentik_certificate_key_pair.default.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "${local.application_url}/accounts/oidc/authentik/login/callback/"
    }
  ]
}

resource "authentik_application" "this" {
  name              = "Tandoor"
  slug              = local.application_slug
  protocol_provider = authentik_provider_oauth2.this.id
  meta_description  = "Recipe management"
  meta_launch_url   = local.application_url
}

resource "authentik_policy_binding" "users" {
  target = authentik_application.this.uuid
  group  = authentik_group.users.id
  order  = 0
}

resource "vault_kv_secret_v2" "oidc" {
  mount        = var.applications_mount_path
  name         = "tandoor/oidc"
  disable_read = true
  data_json_wo = jsonencode({
    clientId     = authentik_provider_oauth2.this.client_id
    clientSecret = authentik_provider_oauth2.this.client_secret
    discoveryUrl = "${var.authentik_url}/application/o/${local.application_slug}/.well-known/openid-configuration"
  })
  data_json_wo_version = 1
}

resource "vault_kv_secret_v2" "runtime" {
  mount        = var.applications_mount_path
  name         = "tandoor/runtime"
  disable_read = true
  data_json_wo = jsonencode({
    secretKey = ephemeral.random_password.runtime_secret_key.result
  })
  data_json_wo_version = local.secret_versions.runtime
}

resource "vault_kv_secret_v2" "backup" {
  mount        = var.applications_mount_path
  name         = "tandoor/backup"
  disable_read = true
  data_json_wo = jsonencode({
    resticPassword = ephemeral.random_password.restic_password.result
  })
  data_json_wo_version = local.secret_versions.backup
}

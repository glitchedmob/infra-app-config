locals {
  application_url  = "https://sparky.levizitting.com"
  ses_from_address = "sparky@levizitting.com"
  ses_policy_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/applications/levizitting-com/LevizittingComSESSender"

  secret_versions = {
    runtime = 1
    smtp    = 1
    backup  = 1
    oidc    = 1
  }
}

ephemeral "random_password" "api_encryption_key" {
  length           = 64
  upper            = false
  lower            = false
  numeric          = false
  special          = true
  override_special = "abcdef0123456789"
}

ephemeral "random_password" "better_auth_secret" {
  length  = 64
  special = false
}

ephemeral "random_password" "restic_password" {
  length  = 40
  special = false
}

data "aws_caller_identity" "current" {}

data "zitadel_organizations" "default" {
  is_default = true
}

resource "aws_iam_user" "ses" {
  name = "sparky-ses-smtp"
  path = "/applications/levizitting-com/"

  tags = {
    Application    = "SparkyFitness"
    Environment    = "production"
    ManagedBy      = "OpenTofu"
    SESFromAddress = local.ses_from_address
  }
}

resource "aws_iam_user_policy_attachment" "ses" {
  user       = aws_iam_user.ses.name
  policy_arn = local.ses_policy_arn
}

resource "aws_iam_access_key" "ses" {
  user = aws_iam_user.ses.name

  depends_on = [aws_iam_user_policy_attachment.ses]
}

resource "zitadel_project" "sparky" {
  name                   = "SparkyFitness"
  org_id                 = one(data.zitadel_organizations.default.ids)
  project_role_assertion = false
  project_role_check     = true
  has_project_check      = false
}

resource "zitadel_project_role" "access" {
  org_id       = one(data.zitadel_organizations.default.ids)
  project_id   = zitadel_project.sparky.id
  role_key     = "access"
  display_name = "SparkyFitness Access"
  group        = "SparkyFitness"
}

resource "zitadel_application_oidc" "sparky" {
  project_id = zitadel_project.sparky.id
  org_id     = one(data.zitadel_organizations.default.ids)

  name                        = "SparkyFitness"
  redirect_uris               = ["${local.application_url}/api/auth/sso/callback/zitadel"]
  access_token_role_assertion = false
  additional_origins          = []
  response_types = [
    "OIDC_RESPONSE_TYPE_CODE",
  ]
  grant_types = [
    "OIDC_GRANT_TYPE_AUTHORIZATION_CODE",
  ]
  post_logout_redirect_uris    = [local.application_url]
  app_type                     = "OIDC_APP_TYPE_WEB"
  auth_method_type             = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                      = "OIDC_VERSION_1_0"
  dev_mode                     = false
  id_token_role_assertion      = false
  id_token_userinfo_assertion  = false
  skip_native_app_success_page = false
}

resource "vault_kv_secret_v2" "oidc" {
  mount        = var.applications_mount_path
  name         = "sparky/oidc"
  disable_read = true
  data_json_wo = jsonencode({
    clientId     = zitadel_application_oidc.sparky.client_id
    clientSecret = zitadel_application_oidc.sparky.client_secret
    issuerUrl    = "https://${var.zitadel_domain}"
  })
  data_json_wo_version = local.secret_versions.oidc
}

resource "vault_kv_secret_v2" "runtime" {
  mount        = var.applications_mount_path
  name         = "sparky/runtime"
  disable_read = true
  data_json_wo = jsonencode({
    apiEncryptionKey = ephemeral.random_password.api_encryption_key.result
    betterAuthSecret = ephemeral.random_password.better_auth_secret.result
  })
  data_json_wo_version = local.secret_versions.runtime
}

resource "vault_kv_secret_v2" "smtp" {
  mount        = var.applications_mount_path
  name         = "sparky/smtp"
  disable_read = true
  data_json_wo = jsonencode({
    smtpFrom     = local.ses_from_address
    smtpPassword = aws_iam_access_key.ses.ses_smtp_password_v4
    smtpUser     = aws_iam_access_key.ses.id
  })
  data_json_wo_version = local.secret_versions.smtp
}

resource "vault_kv_secret_v2" "backup" {
  mount        = var.applications_mount_path
  name         = "sparky/backup"
  disable_read = true
  data_json_wo = jsonencode({
    resticPassword = ephemeral.random_password.restic_password.result
  })
  data_json_wo_version = local.secret_versions.backup
}

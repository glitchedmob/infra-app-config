resource "terraform_data" "rotation" {
  input = var.auth_key_rotation_version
}

resource "headscale_pre_auth_key" "this" {
  user           = var.user_id
  time_to_expire = var.time_to_expire
  reusable       = var.reusable
  ephemeral      = var.ephemeral
  acl_tags       = var.acl_tags

  lifecycle {
    replace_triggered_by = [terraform_data.rotation]
  }
}

resource "aws_ssm_parameter" "this" {
  name             = var.ssm_parameter_name
  type             = "SecureString"
  description      = var.ssm_parameter_description
  value_wo         = headscale_pre_auth_key.this.key
  value_wo_version = var.auth_key_rotation_version
  overwrite        = true
}

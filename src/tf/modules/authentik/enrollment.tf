resource "authentik_flow" "invitation_enrollment" {
  name           = "Invitation enrollment"
  title          = "Create your account"
  slug           = "invitation-enrollment"
  designation    = "enrollment"
  authentication = "require_unauthenticated"
}

resource "authentik_stage_invitation" "enrollment" {
  name                             = "Invitation enrollment"
  continue_flow_without_invitation = false
}

resource "authentik_stage_prompt_field" "password" {
  name        = "Invitation password"
  field_key   = "password"
  label       = "Password"
  type        = "password"
  required    = true
  placeholder = "Password"
  order       = 1
}

resource "authentik_stage_prompt_field" "password_repeat" {
  name        = "Invitation password confirmation"
  field_key   = "password_repeat"
  label       = "Password confirmation"
  type        = "password"
  required    = true
  placeholder = "Password confirmation"
  order       = 2
}

resource "authentik_stage_prompt_field" "name" {
  name        = "Invitation name"
  field_key   = "name"
  label       = "Name"
  type        = "text"
  required    = true
  placeholder = "Name"
  order       = 0
}

resource "authentik_stage_prompt" "credentials" {
  name = "Invitation account details"
  fields = [
    authentik_stage_prompt_field.name.id,
    authentik_stage_prompt_field.password.id,
    authentik_stage_prompt_field.password_repeat.id,
  ]
}

resource "authentik_policy_expression" "invitation_identity" {
  name       = "Require invitation identity"
  expression = <<-EOT
    invitation = request.context.get("invitation")
    fixed_data = invitation.fixed_data if invitation else {}
    username = str(fixed_data.get("username", "")).strip()
    email = str(fixed_data.get("email", "")).strip()

    if not username or not email:
        ak_message("This invitation is missing an administrator-assigned username or email address.")
        return False

    request.context.setdefault("prompt_data", {})["username"] = username
    request.context["prompt_data"]["email"] = email
    return True
  EOT
}

resource "authentik_stage_user_write" "invitation_enrollment" {
  name                     = "Invitation user creation"
  create_users_as_inactive = false
  user_creation_mode       = "always_create"
  user_type                = "internal"
  user_path_template       = "users/internal"
}

resource "authentik_stage_user_login" "invitation_enrollment" {
  name = "Invitation login"
}

resource "authentik_flow_stage_binding" "invitation" {
  target               = authentik_flow.invitation_enrollment.uuid
  stage                = authentik_stage_invitation.enrollment.id
  order                = 5
  re_evaluate_policies = true
}

resource "authentik_flow_stage_binding" "credentials" {
  target = authentik_flow.invitation_enrollment.uuid
  stage  = authentik_stage_prompt.credentials.id
  order  = 10
}

resource "authentik_flow_stage_binding" "user_write" {
  target = authentik_flow.invitation_enrollment.uuid
  stage  = authentik_stage_user_write.invitation_enrollment.id
  order  = 20
}

resource "authentik_policy_binding" "invitation_identity" {
  target = authentik_flow_stage_binding.user_write.id
  policy = authentik_policy_expression.invitation_identity.id
  order  = 0
}

resource "authentik_flow_stage_binding" "user_login" {
  target = authentik_flow.invitation_enrollment.uuid
  stage  = authentik_stage_user_login.invitation_enrollment.id
  order  = 100
}

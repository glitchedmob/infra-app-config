locals {
  ses_from_address = "id@levizitting.com"
  ses_policy_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/applications/levizitting-com/LevizittingComSESSender"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_user" "ses" {
  name = "zitadel-ses-smtp"
  path = "/applications/levizitting-com/"

  tags = {
    Application    = "levizitting.com"
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

resource "zitadel_email_provider_smtp" "ses" {
  host             = "email-smtp.us-east-2.amazonaws.com:587"
  sender_address   = local.ses_from_address
  sender_name      = "ZITADEL"
  reply_to_address = local.ses_from_address
  description      = "Amazon SES"
  tls              = true
  user             = aws_iam_access_key.ses.id
  password         = aws_iam_access_key.ses.ses_smtp_password_v4
  set_active       = true
}

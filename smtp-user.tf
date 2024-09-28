resource "aws_iam_user" "smtp_user" {
  count         = (var.need_smtp_user) ? 1 : 0

  name          = "${var.api_name}-smtp-user"
  force_destroy = "true"
}

resource "aws_iam_access_key" "smtp_user" {
  count         = (var.need_smtp_user) ? 1 : 0

  user = aws_iam_user.smtp_user[0].name
}

data "aws_iam_policy_document" "smtp_user_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "smtp_user_policy" {
  count         = (var.need_smtp_user) ? 1 : 0

  name        = "${var.api_name}-smtp-user-policy"
  description = "Allows sending of emails via Simple Email Service"
  policy      = data.aws_iam_policy_document.smtp_user_policy.json
}

resource "aws_iam_user_policy_attachment" "company_web_ses_attach" {
  count         = (var.need_smtp_user) ? 1 : 0

  user       = aws_iam_user.smtp_user[0].name
  policy_arn = aws_iam_policy.smtp_user_policy[0].arn
}

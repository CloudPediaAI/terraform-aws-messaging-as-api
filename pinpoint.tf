resource "aws_pinpoint_app" "project" {
  for_each = local.all_projects

  name = each.key
}

resource "aws_pinpoint_email_channel" "email" {
  for_each = local.projects_need_email

  application_id = aws_pinpoint_app.project[each.key].application_id
  from_address   = each.value.from_email
  identity = aws_ses_email_identity.email[each.value.from_email].arn
  role_arn = aws_iam_role.pinpoint[each.key].arn
}

# outputs
output "domain_identities" {
  value = aws_ses_domain_identity.domain
}

output "email_identities" {
  value = aws_ses_email_identity.email
}

output "smtp_user" {
  value     = aws_iam_user.smtp_user
  sensitive = false
}

output "smtp_user_access_key" {
  value     = aws_iam_access_key.smtp_user
  sensitive = true
}

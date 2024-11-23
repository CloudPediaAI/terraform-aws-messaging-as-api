locals {
  valid_from_emails          = [for p in local.projects_need_email : p.from_email]
  from_emails_for_identities = flatten([for p in local.projects_need_email : (p.verify_domain_identity) ? [] : [p.from_email]])
  valid_to_emails            = flatten([for p in local.projects_need_email : (p.to_emails != null) ? p.to_emails : []])
  emails_for_identities      = toset(distinct(concat(local.from_emails_for_identities, local.valid_to_emails)))
}

# create all Email identities
resource "aws_ses_email_identity" "email" {
  for_each = local.emails_for_identities

  email = each.value
}

# policy for Email identities
data "aws_iam_policy_document" "email" {
  for_each = aws_ses_email_identity.email

  statement {
    actions   = ["ses:*"]
    resources = [aws_ses_email_identity.email[each.key].arn]


    principals {
      type        = "Service"
      identifiers = ["pinpoint.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }

    condition {
      test     = "StringLike"
      values   = ["arn:aws:mobiletargeting:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apps/*"]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_ses_identity_policy" "email" {
  for_each = aws_ses_email_identity.email

  identity = each.value.arn
  name     = "${replace(replace(each.value.id, "@", "_"), ".", "_")}-identity-policy"
  policy   = data.aws_iam_policy_document.email[each.key].json
}

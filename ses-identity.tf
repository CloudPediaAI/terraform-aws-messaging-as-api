locals {
  valid_from_emails = [for p in local.projects_need_email : p.from_email]
  valid_to_emails   = flatten([for p in local.projects_need_email : p.to_emails])
  email_identities  = toset(distinct(concat(local.valid_from_emails, local.valid_to_emails)))

  valid_domains     = [for p in local.projects_need_email : split("@", p.from_email)[1]]
  domain_identities = toset(distinct(local.valid_domains))
}

# create all Domain identities
resource "aws_ses_domain_identity" "domain" {
  for_each = local.domain_identities

  domain = each.value
}

# policy for Domain identities
data "aws_iam_policy_document" "domain" {
  for_each = aws_ses_domain_identity.domain

  statement {
    actions   = ["ses:*"]
    resources = [aws_ses_domain_identity.domain[each.key].arn]

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

resource "aws_ses_identity_policy" "domain" {
  for_each = aws_ses_domain_identity.domain

  identity = each.value.arn
  name     = "${replace(replace(each.value.id, "@", "_"), ".", "_")}-identity-policy"
  policy   = data.aws_iam_policy_document.domain[each.key].json
}

# create all Email identities
resource "aws_ses_email_identity" "email" {
  for_each = local.email_identities

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

locals {
  valid_domains           = [for p in local.projects_need_email : split("@", p.from_email)[1]]
  domain_identities       = toset(distinct(local.valid_domains))
  valid_domains_to_verify = [for p in local.projects_need_domain_verification : split("@", p.from_email)[1]]
  domains_to_verify       = toset(distinct(local.valid_domains_to_verify))
}

# create all Domain identities
resource "aws_ses_domain_identity" "domain" {
  for_each = local.domain_identities

  domain = each.value
}

# retrieve Hosted Zone using Domain Name
data "aws_route53_zone" "domain_to_verify" {
  for_each = local.domains_to_verify

  name = each.key
}

resource "aws_route53_record" "verification" {
  for_each = data.aws_route53_zone.domain_to_verify

  zone_id = each.value.zone_id
  name    = "_amazonses.${each.value.id}"
  type    = "TXT"
  ttl     = "600"
  # records = [each.value.verification_token]
  records = [aws_ses_domain_identity.domain[each.key].verification_token]
}

resource "aws_ses_domain_identity_verification" "domain_verification" {
  for_each = data.aws_route53_zone.domain_to_verify

  domain     = aws_ses_domain_identity.domain[each.key].id
  depends_on = [aws_route53_record.verification]
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

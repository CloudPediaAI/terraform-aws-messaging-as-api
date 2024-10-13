resource "aws_acm_certificate" "ssl" {
  count = (local.create_custom_domain) ? 1 : 0

  provider          = aws.us-east-1
  domain_name       = local.api_domain_name
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Encode then Decode Validation options to avoid conditional for_each
  domain_validations_str = jsonencode((local.create_custom_domain) ? aws_acm_certificate.ssl[0].domain_validation_options : [
    {
      domain_name           = "dummy"
      resource_record_name  = "dummy"
      resource_record_type  = "CNAME"
      resource_record_value = "dummy"
    },
  ])
  domain_validations = jsondecode(local.domain_validations_str)
  # use first item for validations
  domain_validation  = local.domain_validations[0]
}

resource "aws_route53_record" "dvos" {
  depends_on = [ aws_acm_certificate.ssl ]

  count = (local.create_custom_domain) ? 1 : 0

  zone_id         = local.hosted_zone
  ttl             = 60
  allow_overwrite = true
  name            = local.domain_validation.resource_record_name
  records         = [local.domain_validation.resource_record_value]
  type            = local.domain_validation.resource_record_type
}

resource "aws_acm_certificate_validation" "ssl" {
  depends_on = [aws_route53_record.dvos]

  count = (local.create_custom_domain) ? 1 : 0

  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.ssl[0].arn
  validation_record_fqdns = [for record in aws_route53_record.dvos : record.fqdn]
}

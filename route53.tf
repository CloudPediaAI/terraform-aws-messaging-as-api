# retrive Hosted Zone using ID
data "aws_route53_zone" "by_id" {
  count   = (local.create_custom_domain && local.hosted_zone_provided) ? 1 : 0
  zone_id = var.api_domain_hosted_zone_id
}

# retrieve Hosted Zone using Domain Name
data "aws_route53_zone" "by_name" {
  count = (local.create_custom_domain && !local.hosted_zone_provided) ? 1 : 0
  name  = local.domain_name
}

# extract Hosted Zone Id 
locals {
  hosted_zone = (local.create_custom_domain) ? ((local.hosted_zone_provided) ? data.aws_route53_zone.by_id[0].zone_id : data.aws_route53_zone.by_name[0].zone_id) : "null"
}

resource "aws_api_gateway_domain_name" "api" {
  count   = (local.create_custom_domain) ? 1 : 0

  certificate_arn = aws_acm_certificate_validation.ssl[0].certificate_arn
  domain_name     = local.api_domain_name
}

# creating A records in Route 53 to route traffic to the API
resource "aws_route53_record" "a_record_root" {
  count   = (local.create_custom_domain) ? 1 : 0

  zone_id = local.hosted_zone
  name    = local.api_domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api[0].cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api[0].cloudfront_zone_id
    evaluate_target_health = false
  }
}

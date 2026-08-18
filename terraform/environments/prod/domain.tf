resource "aws_sesv2_email_identity" "business_sender" {
  count = var.enable_request_notifications ? 1 : 0

  email_identity = var.ses_source_email

  tags = local.common_tags
}

resource "aws_route53_zone" "primary" {
  count = var.enable_custom_domain ? 1 : 0

  name = var.domain_name

  tags = local.common_tags
}

resource "aws_acm_certificate" "website" {
  count    = var.enable_custom_domain ? 1 : 0
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

resource "aws_route53_record" "certificate_validation" {
  for_each = var.enable_custom_domain ? {
    for option in aws_acm_certificate.website[0].domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  } : {}

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "website" {
  count    = var.enable_custom_domain_validation ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.website[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}


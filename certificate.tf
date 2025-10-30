data "aws_route53_zone" "uselesschatter" {
  name         = "uselesschatter.com."
  private_zone = false
}

############################
# ACM Certificate (us-east-1)
############################
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  tags = {
    Environment = "dev"
  }
}

#############################################
# Create DNS validation record in Route 53
#############################################
resource "aws_route53_record" "cert_validation" {

  # Prevent errors like:Error: creating Route53 Record: operation error Route 53: ChangeResourceRecordSets
  # InvalidChangeBatch: [Tried to create resource record set but it already exists.  
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  zone_id = data.aws_route53_zone.uselesschatter.id # Hosted Zone ID
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

########################################################
# Validate ACM certificate automatically after DNS is set
########################################################
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

#############################################
# Create DNS alias record in Route 53 for ALB
#############################################
resource "aws_route53_record" "alb_alias" {
  zone_id = data.aws_route53_zone.uselesschatter.id
  name    = "uselesschatter.com"
  type    = "A"
  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "domain" {
  for_each = local.domains

  zone_id = local.zone_id
  name    = each.key
  type    = "A"

  dynamic "alias" {
    for_each = toset([for target in [each.value] : each.key if target == "cloudfront"])
    content {
      name    = aws_cloudfront_distribution.distribution.domain_name
      zone_id = aws_cloudfront_distribution.distribution.hosted_zone_id

      evaluate_target_health = false
    }
  }

  dynamic "alias" {
    for_each = toset([for target in [each.value] : each.key if target == "direct"])
    content {
      name    = data.aws_lb.ambassador.dns_name
      zone_id = data.aws_lb.ambassador.zone_id

      evaluate_target_health = false
    }
  }
}

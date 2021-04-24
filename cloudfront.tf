resource "aws_acm_certificate" "cert" {
  provider = aws.us-east-1

  domain_name       = keys(local.domains)[0]
  validation_method = "DNS"

  subject_alternative_names = slice([for dns, target in local.domains : dns], 1, length(local.domains))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for domain_validation_option in aws_acm_certificate.cert.domain_validation_options : domain_validation_option.domain_name => {
      name   = domain_validation_option.resource_record_name
      type   = domain_validation_option.resource_record_type
      record = domain_validation_option.resource_record_value
    }
  }

  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  zone_id = local.zone_id
  ttl     = 60
}

resource "aws_cloudfront_distribution" "distribution" {
  provider = aws.us-east-1

  depends_on = [
    aws_route53_record.cert_validation
  ]

  origin {
    domain_name = data.aws_lb.ambassador.dns_name
    origin_id   = local.balancer_origin_id

    custom_origin_config {
      http_port  = 80
      https_port = 443
      # For ACME resolution, CloudFront must pass http and https traffic
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true

  aliases = [for dns, target in local.domains : dns]

  #web_acl_id = local.aws_wafv2_arn

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.balancer_origin_id


    forwarded_values {
      query_string = true

      headers = [
        "*"
      ]

      cookies {
        forward = "all"
      }
    }


    # For ACME resolution, CloudFront must pass http and https traffic
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.id
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

locals {
  # Zone ID is something like this: Z1D633PJN98FT9
  zone_id = "YOUR_DNS_ZONE_ID"

  # It is expected that these domains will be resolvable by
  # your zone. In addition, this playbook will create these
  # DNS entries in above zone and bind them to correct target.
  # Zone will also receive multiple DNS validation entries.
  #
  # All of these domains will be registered as SAN for
  # CloudFront certificate.
  # There is a limit on how many SAN's can be served by a
  # single AWS ACM Certificate, default is 10.
  #
  # Targets are selected in domains.tf
  # Target can be "cloudfront" or "direct"
  domains = {
    "www.example.com"       = "cloudfront",
    "subdomain.example.com" = "direct",
  }


  # These must be taken from your ambassador installation
  ambassador_service_name   = "ambassador"
  ambassador_namespace_name = "ambassador"

  # This is Origin ID in CloudFront Distribution.
  # It must be unique per Distribution
  balancer_origin_id = "ambassador"
}

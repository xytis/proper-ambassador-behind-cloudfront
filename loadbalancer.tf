data "kubernetes_service" "ambassador" {
  metadata {
    name      = local.ambassador_service_name
    namespace = local.ambassador_namespace_name
  }
}

# This step is optional, as kubernetes_service already returns valid hostname that can be used as
# CloudFront origin. However, here you can validate type of the Load Balancer.
data "aws_lb" "ambassador" {
  # This takes the first part from LB hostname, which is the LB name
  name = regex("([[:alnum:]]*)", data.kubernetes_service.ambassador.status.0.load_balancer.0.ingress.0.hostname)[0]
}

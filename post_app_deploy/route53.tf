data "aws_route53_zone" "otel_demo_hosted_zone" {
  name         = "velixor.me"
  private_zone = false
}

# data "aws_lb" "otelapp_alb" {
#   count = var.otel_app_alb_name != "" ? 1 : 0
#   name = var.otel_app_alb_name
# }

# # Only create Route 53 record if the ALB exists
# resource "aws_route53_record" "app_record" {
#   count   = length(data.aws_lb.otelapp_alb) > 0 ? 1 : 0
#   zone_id = data.aws_route53_zone.otel_demo_hosted_zone.zone_id
#   name    = "otel-demo-group10.velixor.me"
#   type    = "A"

#   alias {
#     name                   = data.aws_lb.otelapp_alb[0].dns_name
#     zone_id                = data.aws_lb.otelapp_alb[0].zone_id
#     evaluate_target_health = true
#   }
# }

data "aws_lb" "otelapp_alb" {
  name = "otel-demo-frontend-alb"
}

# Only create Route 53 record if the ALB exists
resource "aws_route53_record" "app_record" {
  zone_id = data.aws_route53_zone.otel_demo_hosted_zone.zone_id
  name    = "otel-demo-group10.velixor.me"
  type    = "A"

  alias {
    name                   = data.aws_lb.otelapp_alb.dns_name
    zone_id                = data.aws_lb.otelapp_alb.zone_id
    evaluate_target_health = true
  }
}

# Associating WAF Web ACL with the Application Load Balancer
resource "aws_wafv2_web_acl_association" "otel_app_waf_association" {
  resource_arn = data.aws_lb.otelapp_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.otel_app_waf.arn
  depends_on = [ aws_route53_record.app_record ]
}
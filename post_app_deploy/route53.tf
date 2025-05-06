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

data "aws_load_balancer" "otelapp_alb" {
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

# data "aws_load_balancer" "otelapp_alb" {
#   name = "ecapp-alb"
# }

# resource "aws_route53_record" "app_record" {
#   zone_id = data.aws_route53_zone.ecapp_hosted_zone.zone_id
#   name    = "ecapp-group10.velixor.me"
#   type    = "A"

#   alias {
#     name                   = aws_lb.ecapp_alb.dns_name
#     zone_id                = aws_lb.ecapp_alb.zone_id
#     evaluate_target_health = true
#   }
# }
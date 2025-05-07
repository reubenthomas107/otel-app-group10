# WAF Web ACL for the Application Load Balancer
resource "aws_wafv2_web_acl" "otel_app_waf" {
  name        = "otelapp-group10-waf"
  description = "WAF for OpenTelemetry application ALB"
  scope       = "REGIONAL" # Regional for ALB integration

  default_action {
    allow {} # Allow traffic unless blocked by rules
  }

  # Rule 1: Rate Limiting rule which blocks IPs exceeding 2000 requests in 5 minutes
  rule {
    name     = "RateLimitRule"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000 # Requests per 5 minutes per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: AWS Managed Common Rule Set which protects against common web exploits
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {} # Use default action of the managed rule
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: AWS Managed Known Bad Inputs Rule Set which blocks malicious inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: AWS Managed Bot Control which protects application against bots
  rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesBotControlMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "OtelAppWAFMetric"
    sampled_requests_enabled   = true
  }

  tags = {
    Name    = "otelapp-group10-waf"
    project = "final"
  }
}

# Associating WAF Web ACL with the Application Load Balancer
resource "aws_wafv2_web_acl_association" "otel_app_waf_association" {
  resource_arn = data.aws_lb.otelapp_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.otel_app_waf.arn
}

# AWS Shield Standard is automatically enabled for all AWS resources (no configuration needed).

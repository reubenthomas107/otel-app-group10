resource "aws_sns_topic" "otel_app_sns" {
  name = "otel-demo-app-group10-sns-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.otel_app_sns.arn
  protocol  = "email"
  endpoint  = var.sns_email
}
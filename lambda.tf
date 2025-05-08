resource "aws_iam_role" "lambda_exec" {
  name = "lambda_otel_discord_exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_ssm_policy" {
  name = "lambda-ssm-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ssm:GetParameter",
        Resource = "arn:aws:ssm:us-east-1:619715105204:parameter/otelapp/discord_webhook_url"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "otel_discord_alert" {
  filename         = "${path.module}/function/lambda.zip" # See zip step below
  function_name    = "otelDiscordAlert"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "discord_notification.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/function/lambda.zip")

  depends_on = [aws_iam_role_policy_attachment.lambda_basic_execution]
}


resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.otel_discord_alert.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.otel_app_sns.arn
}

resource "aws_sns_topic_subscription" "discord_alert_sub" {
  topic_arn = aws_sns_topic.otel_app_sns.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.otel_discord_alert.arn
}
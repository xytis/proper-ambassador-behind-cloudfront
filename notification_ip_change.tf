# Notification destination
resource "aws_sns_topic_subscription" "ip_change_notifications" {
  provider  = aws.us-east-1
  topic_arn = local.ip_change_topic
  protocol  = "lambda"
  endpoint  = aws_lambda_function.security_group_update_lambda.arn
}

# Permission to execute lambda
resource "aws_lambda_permission" "ip_change_notifications" {
  provider      = aws.us-east-1
  statement_id  = "AllowExecutionFromSNSTopic-AmazonIpSpaceChanged"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_group_update_lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = local.ip_change_topic
}

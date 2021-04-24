# Notification topic
resource "aws_sns_topic" "security_group_notifications" {
  provider = aws.us-east-1
  name     = "${local.eks_cluster_name}-sg-notifications"
}

# Notification destination
resource "aws_sns_topic_subscription" "attacher_security_group_notification" {
  provider  = aws.us-east-1
  topic_arn = aws_sns_topic.security_group_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.node_group_update_lambda.arn
}

# Permission to execute lambda
resource "aws_lambda_permission" "attacher_sg_sns_topic" {
  statement_id  = "AllowExecutionFromSNSTopic-${aws_sns_topic.security_group_notifications.name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_group_update_lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.security_group_notifications.arn
}

# Notification topic
resource "aws_sns_topic" "autoscaling_group_notifications" {
  name = "${local.eks_cluster_name}-ag-notifications"
}

# Notification source
resource "aws_autoscaling_notification" "autoscaling_group_notifications" {
  group_names = local.eks_autoscaling_groups

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
  ]

  topic_arn = aws_sns_topic.autoscaling_group_notifications.arn
}

# Notification destination
resource "aws_sns_topic_subscription" "attacher_autoscaling_group_notifications" {
  topic_arn = aws_sns_topic.autoscaling_group_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.node_group_update_lambda.arn
}

# Permission to execute lambda
resource "aws_lambda_permission" "attacher_autoscaling_group_notifications" {
  statement_id  = "AllowExecutionFromSNSTopic-${aws_sns_topic.autoscaling_group_notifications.name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_group_update_lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.autoscaling_group_notifications.arn
}

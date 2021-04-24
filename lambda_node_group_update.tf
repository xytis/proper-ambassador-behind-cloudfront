data "archive_file" "node_group_update_lambda_zip" {
  type        = "zip"
  source_dir  = "lambda-node-group-update"
  output_path = "${path.module}/.generated/lambda-node-group-update.zip"
}

resource "aws_lambda_function" "node_group_update_lambda" {
  description      = "AWS Lambda to attach dynamic security group to EKS instances"
  filename         = "${path.module}/.generated/lambda-node-group-update.zip"
  source_code_hash = data.archive_file.node_group_update_lambda_zip.output_base64sha256
  function_name    = "${local.eks_cluster_name}-node-group-update-lambda"
  role             = aws_iam_role.node_group_update_lambda_role.arn
  handler          = "lambda.lambda_handler"
  runtime          = "python3.8"
  timeout          = 10

  environment {
    variables = {
      VPC_ID       = local.vpc_id
      PREFIX_NAME  = local.security_group_prefix
      REGION       = local.target_region
      CLUSTER_NAME = local.eks_cluster_name
    }
  }
}

data "aws_iam_policy_document" "node_group_update_lambda_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "node_group_update_lambda_role" {
  name               = "${local.eks_cluster_name}-node-group-update-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.node_group_update_lambda_role_assume.json
}

# Permission to execute
resource "aws_iam_role_policy_attachment" "node_group_update_lambda_execution" {
  role       = aws_iam_role.node_group_update_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Execution permissions
resource "aws_iam_role_policy" "attacher_lambda_execution_custom" {
  name   = "execution-role"
  role   = aws_iam_role.node_group_update_lambda_role.name
  policy = data.aws_iam_policy_document.node_group_update_lambda_execution.json
}

data "aws_iam_policy_document" "node_group_update_lambda_execution" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
  statement {
    actions = [
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "autoscaling:DescribeAutoScalingGroups",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateTags",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "sns:Subscribe",
    ]
    resources = [
      aws_sns_topic.autoscaling_group_notifications.arn,
      aws_sns_topic.security_group_notifications.arn,
    ]
  }
}

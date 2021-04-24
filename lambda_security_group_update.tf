data "archive_file" "security_group_update_lambda_zip" {
  type        = "zip"
  source_dir  = "lambda-security-group-update"
  output_path = "${path.module}/.generated/lambda-security-group-update.zip"
}

resource "aws_lambda_function" "security_group_update_lambda" {
  provider = aws.us-east-1

  description      = "AWS Lambda to generate dynamic security group based on CloudFront IPs"
  filename         = "${path.module}/.generated/lambda-security-group-update.zip"
  source_code_hash = data.archive_file.security_group_update_lambda_zip.output_base64sha256
  function_name    = "${local.eks_cluster_name}-security-group-update-lambda"
  role             = aws_iam_role.security_group_update_lambda_role.arn
  handler          = "lambda.lambda_handler"
  runtime          = "python3.8"
  timeout          = 10

  environment {
    variables = {
      VPC_ID        = local.vpc_id
      PORTS         = join(",", local.ports)
      PREFIX_NAME   = local.security_group_prefix
      REGION        = local.target_region
      SNS_TOPIC_ARN = aws_sns_topic.security_group_notifications.arn
    }
  }
}

data "aws_iam_policy_document" "security_group_update_lambda_role_assume" {
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

resource "aws_iam_role" "security_group_update_lambda_role" {
  name               = "${local.eks_cluster_name}-security-group-update-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.security_group_update_lambda_role_assume.json
}

# Permission to execute
resource "aws_iam_role_policy_attachment" "security_group_update_lambda_execution" {
  role       = aws_iam_role.security_group_update_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Execution permissions
resource "aws_iam_role_policy" "security_group_update_lambda_execution" {
  name   = "execution-role"
  role   = aws_iam_role.security_group_update_lambda_role.name
  policy = data.aws_iam_policy_document.security_group_update_lambda_execution.json
}

data "aws_iam_policy_document" "security_group_update_lambda_execution" {
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
      "ec2:DescribeSecurityGroups",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DescribeVpcs",
      "ec2:CreateTags",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:DescribeNetworkInterfaces",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.security_group_notifications.arn,
    ]
  }
}


data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "apigateway.amazonaws.com",
        "lambda.amazonaws.com",
        "pinpoint.amazonaws.com"
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  for_each = local.projects_need_api

  name               = "${var.api_name}-${each.key}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "send_email" {
  statement {
    effect = "Allow"

    actions = [
      "mobiletargeting:SendMessages",
      "ses:SendEmail",
      "ses:SendRawEmail",
      "lambda:InvokeFunction"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "pinpoint_lambda_role_policy" {
  for_each = aws_iam_role.lambda

  name   = "${each.value.name}-policy"
  role   = each.value.id
  policy = data.aws_iam_policy_document.send_email.json
}

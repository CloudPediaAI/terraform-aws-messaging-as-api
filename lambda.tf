# create lambda package for send-email
data "archive_file" "lambda_pkg_send_email" {
  type        = "zip"
  source_file  = "${path.module}/send_email.js"
  output_path = "send-email-lambda.zip"
}

# create lambda for send-email
resource "aws_lambda_function" "send_email" {
  for_each = local.email_projects_need_api

  function_name    = "${var.api_name}-${each.key}-send-email"
  description      = "send emails using Pinpoint"
  filename         = "send-email-lambda.zip"
  source_code_hash = data.archive_file.lambda_pkg_send_email.output_base64sha256
  role             = aws_iam_role.lambda[each.key].arn
  runtime          = "nodejs20.x"
  handler          = "send_email.handler"
  timeout          = 180

  environment {
    variables = {
      "CURRENT_REGION": data.aws_region.current.name,
      "PINPOINT_APP_ID" : aws_pinpoint_app.project[each.key].application_id,
      "FROM_EMAIL_ID" : each.value.from_email
    }
  }

  tags = var.tags
}


# create lambda package for register-number
data "archive_file" "lambda_pkg_register_number" {
  type        = "zip"
  source_file  = "${path.module}/register_number.js"
  output_path = "register-number-lambda.zip"
}

# create lambda for send-sms
resource "aws_lambda_function" "register_number" {
  for_each = local.sms_projects_need_api

  function_name    = "${var.api_name}-${each.key}-register-number"
  description      = "Lambda to validate and register phone number in Pinpoint"
  filename         = "register-number-lambda.zip"
  source_code_hash = data.archive_file.lambda_pkg_register_number.output_base64sha256
  role             = aws_iam_role.lambda[each.key].arn
  runtime          = "nodejs20.x"
  handler          = "register_number.handler"
  timeout          = 180

  environment {
    variables = {
      "CURRENT_REGION": data.aws_region.current.name,
      "PINPOINT_APP_ID" : aws_pinpoint_app.project[each.key].application_id,
      "ORIGINATION_NUMBER" : each.value.sms_origination_number
    }
  }

  tags = var.tags
}

# create lambda package for send-sms
data "archive_file" "lambda_pkg_send_sms" {
  type        = "zip"
  source_file  = "${path.module}/send_sms.js"
  output_path = "send-sms-lambda.zip"
}

# create lambda for send-sms
resource "aws_lambda_function" "send_sms" {
  for_each = local.sms_projects_need_api

  function_name    = "${var.api_name}-${each.key}-send-sms"
  description      = "send SMS using Pinpoint"
  filename         = "send-sms-lambda.zip"
  source_code_hash = data.archive_file.lambda_pkg_send_sms.output_base64sha256
  role             = aws_iam_role.lambda[each.key].arn
  runtime          = "nodejs20.x"
  handler          = "send_sms.handler"
  timeout          = 180

  environment {
    variables = {
      "CURRENT_REGION": data.aws_region.current.name,
      "PINPOINT_APP_ID" : aws_pinpoint_app.project[each.key].application_id,
      "ORIGINATION_NUMBER" : each.value.sms_origination_number
    }
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "send_email" {
  for_each = local.email_projects_need_api

  parent_id   = aws_api_gateway_resource.project[each.key].id
  path_part   = "send-email"
  rest_api_id = aws_api_gateway_rest_api.messaging[0].id
}

resource "aws_api_gateway_method" "send_email_post" {
  for_each = aws_api_gateway_resource.send_email

  authorization = local.auth_types.NONE
  # authorizer_id = (local.auth_type == local.auth_types.COGNITO) ? aws_api_gateway_authorizer.cognito[0].id : null
  http_method = local.http_methods.POST
  resource_id = each.value.id
  rest_api_id = aws_api_gateway_resource.project[each.key].rest_api_id
}

resource "aws_api_gateway_integration" "send_email_int" {
  for_each = aws_api_gateway_method.send_email_post

  rest_api_id             = aws_api_gateway_rest_api.messaging[0].id
  resource_id             = aws_api_gateway_resource.send_email[each.key].id
  http_method             = each.value.http_method
  integration_http_method = local.http_methods.POST
  type                    = local.integration_types.AWS_PROXY
  uri                     = aws_lambda_function.send_email[each.key].invoke_arn
}

resource "aws_api_gateway_method_response" "send_email_post_res_200" {
  for_each = aws_api_gateway_integration.send_email_int

  rest_api_id = aws_api_gateway_rest_api.messaging[0].id
  resource_id = aws_api_gateway_resource.send_email[each.key].id
  http_method = each.value.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "send_email_int_res" {
  for_each = aws_api_gateway_method_response.send_email_post_res_200

  rest_api_id = aws_api_gateway_rest_api.messaging[0].id
  resource_id = aws_api_gateway_resource.send_email[each.key].id
  http_method = each.value.http_method
  status_code = aws_api_gateway_method_response.send_email_post_res_200[each.key].status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
    errorMessage: $inputRoot.body;
}
EOF
  }
}

resource "aws_lambda_permission" "send_email_post" {
  for_each = aws_api_gateway_method.send_email_post

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_email[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.messaging[0].id}/*/${each.value.http_method}${aws_api_gateway_resource.send_email[each.key].path}"
}

resource "aws_api_gateway_resource" "register_number" {
  for_each = local.sms_projects_need_api

  parent_id   = aws_api_gateway_resource.project[each.key].id
  path_part   = "register-number"
  rest_api_id = aws_api_gateway_rest_api.messaging[0].id
}

resource "aws_api_gateway_method" "register_number_post" {
  for_each = aws_api_gateway_resource.register_number

  authorization = local.auth_types.NONE
  # authorizer_id = (local.auth_type == local.auth_types.COGNITO) ? aws_api_gateway_authorizer.cognito[0].id : null
  http_method = local.http_methods.POST
  resource_id = each.value.id
  rest_api_id = aws_api_gateway_resource.project[each.key].rest_api_id
}

resource "aws_api_gateway_integration" "register_number_int" {
  for_each = aws_api_gateway_method.register_number_post

  rest_api_id             = aws_api_gateway_rest_api.messaging[0].id
  resource_id             = aws_api_gateway_resource.register_number[each.key].id
  http_method             = each.value.http_method
  integration_http_method = local.http_methods.POST
  type                    = local.integration_types.AWS
  uri                     = aws_lambda_function.register_number[each.key].invoke_arn

  request_templates = {
    "application/json" = <<EOF
#set( $bodyStr = $util.parseJson($input.body) )
#if( $bodyStr != "" )
{
    "httpMethod": "$context.httpMethod", 
    "body": $input.body
}
#else
{
    "httpMethod": "ERROR-BODY"
}
#end
EOF
  }

}

resource "aws_api_gateway_method_response" "register_number_post_res_200" {
  for_each = aws_api_gateway_integration.register_number_int

  rest_api_id = aws_api_gateway_rest_api.messaging[0].id
  resource_id = aws_api_gateway_resource.register_number[each.key].id
  http_method = each.value.http_method
  status_code = "200"

  //cors section
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "register_number_int_res_200" {
  for_each = aws_api_gateway_method_response.register_number_post_res_200

  rest_api_id = aws_api_gateway_rest_api.messaging[0].id
  resource_id = aws_api_gateway_resource.register_number[each.key].id
  http_method = each.value.http_method
  status_code = aws_api_gateway_method_response.register_number_post_res_200[each.key].status_code

  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

#   response_templates = {
#     "application/json" = <<EOF
# #set($inputRoot = $input.path('$'))
# {
#     errorMessage: $inputRoot.body;
# }
# EOF
#   }

  depends_on = [
    aws_api_gateway_method.register_number_post,
    aws_api_gateway_integration.register_number_int
  ]
}

resource "aws_api_gateway_method_response" "register_number_post_res_400" {
  for_each = aws_api_gateway_integration.register_number_int

  rest_api_id = aws_api_gateway_rest_api.messaging[0].id
  resource_id = aws_api_gateway_resource.register_number[each.key].id
  http_method = each.value.http_method
  status_code = "400"
}

resource "aws_api_gateway_integration_response" "register_number_int_res_400" {
  for_each = aws_api_gateway_method_response.register_number_post_res_400

  selection_pattern = ".*\"errorCode\":400.*"
  rest_api_id       = aws_api_gateway_rest_api.messaging[0].id
  resource_id       = aws_api_gateway_resource.register_number[each.key].id
  http_method       = each.value.http_method
  status_code       = aws_api_gateway_method_response.register_number_post_res_400[each.key].status_code

  response_templates = {
    "application/json" = "$input.path('$.errorMessage')"
  }

  depends_on = [
    aws_api_gateway_method.register_number_post,
    aws_api_gateway_integration.register_number_int
  ]
}


resource "aws_api_gateway_method_response" "register_number_post_res_500" {
  for_each = aws_api_gateway_integration.register_number_int

  rest_api_id = aws_api_gateway_rest_api.messaging[0].id
  resource_id = aws_api_gateway_resource.register_number[each.key].id
  http_method = each.value.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "register_number_int_res_500" {
  for_each = aws_api_gateway_method_response.register_number_post_res_500

  selection_pattern = ".*\"errorCode\":500.*"
  rest_api_id       = aws_api_gateway_rest_api.messaging[0].id
  resource_id       = aws_api_gateway_resource.register_number[each.key].id
  http_method       = each.value.http_method
  status_code       = aws_api_gateway_method_response.register_number_post_res_500[each.key].status_code

  response_templates = {
    "application/json" = "$input.path('$.errorMessage')"
  }

  depends_on = [
    aws_api_gateway_method.register_number_post,
    aws_api_gateway_integration.register_number_int
  ]
}

resource "aws_lambda_permission" "register_number_post" {
  for_each = aws_api_gateway_method.register_number_post

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_number[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.messaging[0].id}/*/${each.value.http_method}${aws_api_gateway_resource.register_number[each.key].path}"
}

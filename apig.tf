locals {
  http_methods = {
    GET    = "GET",
    POST   = "POST",
    PUT    = "PUT",
    DELETE = "DELETE"
  }

  integration_types = {
    MOCK       = "MOCK",      # not calling any real backend
    AWS        = "AWS",       # for AWS services
    HTTP       = "HTTP",      # for HTTP backends 
    AWS_PROXY  = "AWS_PROXY"  # for Lambda proxy integration
    HTTP_PROXY = "HTTP_PROXY" # for HTTP proxy integration
  }

  auth_types = {
    NONE    = "NONE",
    CUSTOM  = "CUSTOM",
    AWSIAM  = "AWS_IAM",
    COGNITO = "COGNITO_USER_POOLS"
  }
}

resource "aws_api_gateway_rest_api" "messaging" {
  count = (length(local.projects_need_api) > 0) ? 1 : 0

  name = "${var.api_name}-api"
  tags = var.tags
}

# create endpoints for each projects
resource "aws_api_gateway_resource" "project" {
  for_each = local.projects_need_api

  parent_id   = aws_api_gateway_rest_api.messaging[0].root_resource_id
  path_part   = each.key
  rest_api_id = aws_api_gateway_rest_api.messaging[0].id
}

locals {
  api_resource_ids = flatten([
    for key, value in aws_api_gateway_resource.project : [
      {
        id = aws_api_gateway_resource.project[key].id
      }
    ]
  ])

  api_method_ids = flatten([
    for key, value in aws_api_gateway_method.send_email_post : [
      {
        id = aws_api_gateway_method.send_email_post[key].id
      }
    ]
  ])

  api_integration_ids = flatten([
    for key, value in aws_api_gateway_integration.send_email_int : [
      {
        id = aws_api_gateway_integration.send_email_int[key].id
      }
    ]
  ])

  api_method_response_200_ids = flatten([
    for key, value in aws_api_gateway_method_response.send_email_post_res_200 : [
      {
        id = aws_api_gateway_method_response.send_email_post_res_200[key].id
      }
    ]
  ])

  api_method_response_400_ids = flatten([
    for key, value in aws_api_gateway_method_response.send_email_post_res_400 : [
      {
        id = aws_api_gateway_method_response.send_email_post_res_400[key].id
      }
    ]
  ])

  api_method_response_500_ids = flatten([
    for key, value in aws_api_gateway_method_response.send_email_post_res_500 : [
      {
        id = aws_api_gateway_method_response.send_email_post_res_500[key].id
      }
    ]
  ])

  api_integration_response_200_ids = flatten([
    for key, value in aws_api_gateway_integration_response.send_email_int_res_200 : [
      {
        id = aws_api_gateway_integration_response.send_email_int_res_200[key].id
      }
    ]
  ])

  api_integration_response_400_ids = flatten([
    for key, value in aws_api_gateway_integration_response.send_email_int_res_400 : [
      {
        id = aws_api_gateway_integration_response.send_email_int_res_400[key].id
      }
    ]
  ])

  api_integration_response_500_ids = flatten([
    for key, value in aws_api_gateway_integration_response.send_email_int_res_500 : [
      {
        id = aws_api_gateway_integration_response.send_email_int_res_500[key].id
      }
    ]
  ])

}

resource "aws_api_gateway_deployment" "main_deploy" {
  count = (length(local.projects_need_api) > 0) ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.messaging[0].id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      local.api_resource_ids,
      local.api_method_ids, local.api_method_response_200_ids, local.api_method_response_400_ids, local.api_method_response_500_ids,
      local.api_integration_ids, local.api_integration_response_200_ids, local.api_integration_response_200_ids, local.api_integration_response_200_ids,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  count = (local.create_custom_domain) ? 1 : 0

  deployment_id = aws_api_gateway_deployment.main_deploy[0].id
  rest_api_id   = aws_api_gateway_rest_api.messaging[0].id
  stage_name    = "prod_${var.api_version}"
}

resource "aws_api_gateway_base_path_mapping" "prod" {
  count = (local.create_custom_domain) ? 1 : 0

  api_id      = aws_api_gateway_rest_api.messaging[0].id
  stage_name  = aws_api_gateway_stage.prod[0].stage_name
  domain_name = aws_api_gateway_domain_name.api[0].domain_name
  base_path   = var.api_version
}

# count         = (var.cognito_user_pool_arns != null && length(var.cognito_user_pool_arns) > 0) ? 1 : 0
# resource "aws_api_gateway_authorizer" "cognito" {
#   count = (local.auth_type == local.auth_types.COGNITO) ? 1 : 0

#   name          = "CognitoUserPoolAuthorizer"
#   type          = local.auth_type
#   rest_api_id   = aws_api_gateway_rest_api.main.id
#   provider_arns = var.cognito_user_pool_arns
# }

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # creating list of projects by avoiding invalid projects
  all_projects = {
    for key, project_info in var.projects : key => project_info if(project_info != null && project_info.channels != null)
  }

  # creating list of projects which requires SMS channel
  projects_need_sms = {
    for key, project_info in local.all_projects : key => project_info if(contains(project_info.channels, "sms"))
  }

  # creating list of projects which requires API Endpoints
  projects_need_api = {
    for key, project_info in local.all_projects : key => project_info if(project_info.need_api_endpoint)
  }

  email_projects_need_api = {
    for key, project_info in local.projects_need_api : key => project_info if(project_info.need_api_endpoint)
  }

  sms_projects_need_api = {
    for key, project_info in local.projects_need_api : key => project_info if(project_info.need_api_endpoint)
  }

  # creating list of projects which requires EMAIL channel
  projects_need_email = {
    for key, project_info in local.all_projects : key => project_info if(contains(project_info.channels, "email"))
  }

  projects_need_domain_verification = {
    for key, project_info in local.projects_need_email : key => project_info if(project_info.verify_domain_identity)
  }

  create_api_gateway   = (length(local.projects_need_api) > 0)
  hosted_zone_provided = (var.api_domain_hosted_zone_id != null)
  domain_provided      = (var.api_domain_name != "null")
  create_custom_domain = local.create_api_gateway && (local.hosted_zone_provided || local.domain_provided)

  domain_name     = (local.create_custom_domain) ? ((local.domain_provided) ? lower(var.api_domain_name) : data.aws_route53_zone.by_id[0].name) : null
  api_domain_name = (local.create_custom_domain) ? "${lower(var.api_name)}.${local.domain_name}" : null
  custom_api_url  = (local.create_custom_domain) ? "https://${lower(var.api_name)}.${local.domain_name}/${var.api_version}" : null
  api_base_url    = local.create_api_gateway ? ((local.create_custom_domain) ? local.custom_api_url : aws_api_gateway_stage.prod[0].invoke_url) : ""

  api_endpoints_send_email = flatten([
    for key, value in local.email_projects_need_api : {
      "${key}" = {
        "${key}-email" : "${local.api_base_url}${aws_api_gateway_resource.send_email[key].path}"
      }
    }
    ]
  )

  api_endpoints = concat(local.api_endpoints_send_email)

}

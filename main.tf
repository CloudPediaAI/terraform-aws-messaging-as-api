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

}

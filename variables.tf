variable "api_name" {
  type        = string
  default     = "messaging"
  description = "Name for your API. Default value is 'Messaging'"
  # validation {
  #   condition = (can(regex("^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\\.)*([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])$", var.api_name))
  #     && !strcontains(var.api_name, "..")
  #     && !startswith(var.api_name, "xn--")
  #     && !startswith(var.api_name, "sthree-")
  #     && !endswith(var.api_name, "-s3alias")
  #   && !endswith(var.api_name, "--ol-s3"))
  #   error_message = "Provide API name only contain alphanumeric characters, hyphens, and underscores."
  # }
}

variable "api_domain_name" {
  type        = string
  default     = "null"
  description = "Domain name to configure URL for the messaging API"
  validation {
    condition = (can(regex("^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\\.)*([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])$", var.api_domain_name))
      && !strcontains(var.api_domain_name, "..")
      && !startswith(var.api_domain_name, "xn--")
      && !startswith(var.api_domain_name, "sthree-")
      && !endswith(var.api_domain_name, "-s3alias")
    && !endswith(var.api_domain_name, "--ol-s3"))
    error_message = "Provide a valid domain name."
  }
}

variable "api_domain_hosted_zone_id" {
  type        = string
  default     = null
  description = "Id of the Hosted Zone in Route 53.  This is not required if api_domain_name provided"
}

variable "api_version" {
  type        = string
  default     = "v1"
  description = "Give a version number prefixed with v. This will be used as part of base-path for API URL. Default is v1"
}

variable "projects" {
  type = map(object({
    channels               = list(string)
    from_email             = string
    to_emails              = list(string)
    sms_origination_number = string
    need_api_endpoint      = bool
    verify_domain_identity = bool
  }))
  description = "List of Projects to build Messaging channels (Project details as Map(Object('Project-Name'={channels=['email','sms'], from_email='sender@domain.com', to_emails=['recepient1@domain.com','recepient2@domain.com'] need_api_endpoint=true}))"
}

variable "need_smtp_user" {
  type        = bool
  default     = false
  description = "Set true if user wants to send emails using SMTP"
}

variable "tags" {
  type        = map(any)
  description = "Key/Value pairs for the tags"
  default = {
    created_by = "Terraform Module CloudPediaAI/Messaging-as-API/aws"
  }
}

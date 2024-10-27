##---------------------------------------##
### Common IAM Role and Policy for Pinpoint
##---------------------------------------##

# assume role for pinpoint
data "aws_iam_policy_document" "pinpoint_assumerole" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pinpoint.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# create assume role for all projects
resource "aws_iam_role" "pinpoint" {
  for_each = local.all_projects

  name               = "${var.api_name}-${each.key}-pinpoint-role"
  assume_role_policy = data.aws_iam_policy_document.pinpoint_assumerole.json
}

# IAM policy for Pinpoint analytics
data "aws_iam_policy_document" "pinpoint_analytics" {
  statement {
    effect = "Allow"

    actions = [
      "mobileanalytics:PutEvents",
      "mobileanalytics:PutItems"
    ]

    resources = ["*"]
  }
}

# Attach Pinpoint Analytics Policy to all IAM roles 
resource "aws_iam_role_policy" "pinpoint_role_policy" {
  for_each = aws_iam_role.pinpoint

  name   = "${each.value.name}-policy"
  role   = each.value.id
  policy = data.aws_iam_policy_document.pinpoint_analytics.json
}

##---------------------------------------##
### IAM Role and Policy for sending SMS
##---------------------------------------##

# create IAM role for SMS projects
resource "aws_iam_role" "pinpoint_sms" {
  for_each = local.projects_need_sms

  name               = "${var.api_name}-${each.key}-pinpoint-sms-role"
  assume_role_policy = data.aws_iam_policy_document.pinpoint_assumerole.json
}

# Create IAM policies and roles for use with SMS in Amazon Pinpoint
data "aws_iam_policy_document" "pinpoint_sms" {
  for_each = aws_iam_role.pinpoint_sms

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["mobiletargeting:SendMessages"]
    resources = ["arn:aws:mobiletargeting:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apps/${aws_pinpoint_app.project[each.key].application_id}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "mobiletargeting:GetEndpoint",
      "mobiletargeting:UpdateEndpoint",
      "mobiletargeting:PutEvents"
    ]

    resources = ["arn:aws:mobiletargeting:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apps/${aws_pinpoint_app.project[each.key].application_id}/endpoints/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["mobiletargeting:PhoneNumberValidate"]
    resources = ["arn:aws:mobiletargeting:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:phone/number/validate"]
  }
}

# Attach Pinpoint SMS Policy to SMS IAM roles 
resource "aws_iam_role_policy" "pinpoint_sms_role_policy" {
  for_each = aws_iam_role.pinpoint_sms

  name   = "${each.value.name}-policy-sms"
  role   = each.value.id
  policy = data.aws_iam_policy_document.pinpoint_sms[each.key].json
}


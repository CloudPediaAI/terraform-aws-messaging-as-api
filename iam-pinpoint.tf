
data "aws_iam_policy_document" "test_pinpoint_assumerole" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pinpoint.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "pinpoint" {
  for_each = local.all_projects

  name               = "${var.api_name}-${each.key}-pinpoint-role"
  assume_role_policy = data.aws_iam_policy_document.test_pinpoint_assumerole.json
}

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

resource "aws_iam_role_policy" "test_role_policy" {
  for_each = aws_iam_role.pinpoint

  name   = "${each.value.name}-policy"
  role   = each.value.id
  policy = data.aws_iam_policy_document.pinpoint_analytics.json
}

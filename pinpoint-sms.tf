resource "aws_pinpoint_sms_channel" "sms" {
  for_each = local.projects_need_sms

  application_id = aws_pinpoint_app.project[each.key].application_id
}

# resource "aws_pinpointsmsvoicev2_phone_number" "originator" {
#   for_each = local.projects_need_sms

#   iso_country_code = "US"
#   message_type     = "TRANSACTIONAL"
#   number_type      = "TOLL_FREE"

#   number_capabilities = [
#     "SMS"
#   ]
# }
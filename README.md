# Messaging as API
This terraform module will create a REST API to send Emails, SMS and Push Notifications using Amazon Pinpoint.  You just provide the list of Projects, domain/email identities, this module will create projects and channels in Amazon Pinpoint and will generate REST API endpoints accordingly.

## Pipoint is Regional 
The Amazon Pinpoint API is available in several AWS Regions and it provides an endpoint for each of these Regions. Also some of the  Pinpoint service are not available in few regions.  See [Amazon Pinpoint endpoints and quotas in the Amazon Web Services General Reference](https://docs.aws.amazon.com/general/latest/gr/pinpoint.html)


# Links

- [Documentation](https://cloudpedia.ai/terraform-module/aws-messaging-as-api/)
- [Terraform module](https://registry.terraform.io/modules/cloudpediaai/messaging-as-api/aws/latest)
- [GitHub Repo](https://github.com/CloudPediaAI/terraform-aws-messaging-as-api)


## v1.0.0
Features released
- Amazon Pinpoint Email channel 
- POST endpoints and Lambda for sending emails
- SMTP User 


# Receive emails from Email Alert API in Integration and Staging

In order to test receiving real emails from Email Alert API we have configured
Google groups for the Integration and Staging environments. Emails
sent to addresses other than those of these groups will be
[written to a logfile][logging-emails], and you can view them
through Logit - see [this example query][logit-query].

The default configuration in govuk-helm-charts limits emails to
be sent to one email address, which is the Google group for
Integration or Staging. See an [example of this config][helm-charts-config].

The Google group email address also needs to be included in [Notify's
guest list][notify-guest-list].

## In Integration

In Integration there is the [Email Alert API Integration Google
group][integration-group]. It has an email address of
`email-alert-api-integration@digital.cabinet-office.gov.uk`.

This email is associated with an Integration test user account
with GOV.UK One Login, and the credentials are stored in
[AWS Secrets Manager][aws-secrets] as `2ndline/govuk-accounts-integration`.

This email address can be used to sign up to subscriptions on
https://www.integration.publishing.service.gov.uk/.

## In Staging

In Staging there is the [Email Alert API Staging Google
group][staging-group]. It has an email address of
`email-alert-api-staging@digital.cabinet-office.gov.uk`.

This account can be used to sign up to subscriptions on
https://www.staging.publishing.service.gov.uk/.

Please note: There is no staging environment for the govuk account. This means that
you will not be able to test signing up on pages that have a single page notification button,
as that flow requires creating or signing into a govuk account.

## How to use

To use these Google groups you need to interact with the Email Alert system
using the group email as your email address. For example, if you wanted to test
receiving the content change alerts for travel advice, you can
[sign-up to receive travel advice][travel-advice] with the group email address.
Your next step would be to check the Google group for
an email to confirm the subscription. Once confirmed, you can then publish
a change in [Travel Advice Publisher][] to generate the content change
alert email.

If you are testing over multiple days, bear in mind that the
databases are reset due to the [data sync][] in Integration (weekly) and Staging (nightly).
This will mean that any test subscriptions you've created will be lost and
you'll need to recreate them.

## Troubleshooting

You might be prompted for http basic auth when you are passed through the account authentication process. 
If so, those credentials are listed in [AWS Secrets Manager][aws-secrets] as `2ndline/govuk-accounts-integration`

[logging-emails]: https://github.com/alphagov/email-alert-api/blob/006afa2ee6c35631b83b16519f8af2c6c2ea5c59/app/services/send_email_service/send_pseudo_email.rb#L10-L20
[integration-group]: https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-integration
[travel-advice]: https://www.integration.publishing.service.gov.uk/foreign-travel-advice/thailand/email-signup
[Travel Advice Publisher]: https://travel-advice-publisher.integration.publishing.service.gov.uk/admin/countries/thailand
[staging-group]: https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-staging
[data sync]: https://docs.publishing.service.gov.uk/manual/govuk-env-sync.html
[aws-secrets]: https://docs.publishing.service.gov.uk/manual/secrets-manager.html
[logit-query]: https://kibana.logit.io/s/42f4d2d5-e9ce-451f-8ffc-cdb25bd624f8/goto/1633450c81219a1bab69e3f582520d0f?security_tenant=global
[helm-charts-config]: https://github.com/alphagov/govuk-helm-charts/blob/948ddd80fe7a09482c532a73507a455790c47eac/charts/app-config/values-integration.yaml#L1069-L1070
[notify-guest-list]: https://www.notifications.service.gov.uk/services/b5213d78-8e54-4e76-8c0c-0adba7670579/api/guest-list

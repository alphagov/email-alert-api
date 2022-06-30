# Receive emails from Email Alert API in Integration and Staging

In order to test receiving real emails from Email Alert API we have configured
Google groups for the integration and staging environments. Emails
sent to addresses other than those of these groups will be
[written to a logfile][logging-emails].

> Note that these two emails are sometimes accidentally used to sign up to GOV.UK
accounts. If you try to test a signup and are stopped by the requirement to log
into an account, you can fix using the procedure below under "Troubleshooting"

## In Integration

In Integration there is the [Email Alert API Integration Google
group][integration-group]. It has an email address of
`email-alert-api-integration@digital.cabinet-office.gov.uk`.

This account can be used to sign up to subscriptions on
https://www.integration.publishing.service.gov.uk/.

## In Staging

In Staging there is the [Email Alert API Staging Google
group][staging-group]. It has an email address of
`email-alert-api-staging@digital.cabinet-office.gov.uk`.

This account can be used to sign up to subscriptions on
https://www.staging.publishing.service.gov.uk/.

## How to use

To use these Google groups you need to interact with the Email Alert system
using the group email as your email address. For example, if you wanted to test
receiving the content change alerts for travel advice, you can
[sign-up to receive travel advice][travel-advice] with the group email address.
Your next step would be to check the Google group for
an email to confirm the subscription. Once confirmed, you can then publish
a change in [Travel Advice Publisher][] to generate the content change
alert email.

If you are testing over multiple days, bear in mind that each night the
databases in Integration and Staging are reset due to the [data sync][].
This will mean that any test subscriptions you've created will be lost and
you'll need to recreate them.

## Troubleshooting

Sometimes these email addresses get linked to GOV.UK accounts, making them impossible to use for testing these journeys. If that happens, you can use the accounts-api console in the relevant environment to clear the account:

```
% gds govuk connect app-console -e integration account-api
> OidcUser.where(email: "email-alert-api-integration@digital.cabinet-office.gov.uk").delete_all
```

[logging-emails]: https://github.com/alphagov/email-alert-api/blob/006afa2ee6c35631b83b16519f8af2c6c2ea5c59/app/services/send_email_service/send_pseudo_email.rb#L10-L20
[integration-group]: https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-integration
[travel-advice]: https://www.integration.publishing.service.gov.uk/foreign-travel-advice/thailand/email-signup
[Travel Advice Publisher]: https://travel-advice-publisher.integration.publishing.service.gov.uk/admin/countries/thailand
[staging-group]: https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-staging
[data sync]: /manual/govuk-env-sync.html

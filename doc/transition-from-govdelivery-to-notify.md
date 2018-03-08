# Transition from Govdelivery to Notify

This document serves as documentation for the transition from Govdelivery to
Notify as the means to send emails. The intention is that this stores
information related to the migration and this app close to the codebase.
It will be safe to remove this once the migration has been completed.

## ENV vars

### `USE_EMAIL_ALERT_FRONTEND_FOR_EMAIL_COLLECTION`

When this environment variable set the redirect location that is returned
as part of a subscriber list JSON serialization. Once this is returning
frontend apps will redirect users to the Email Alert Frontend signup which
does not use govdelivery.

### `EMAIL_ADDRESS_OVERRIDE`

By setting this environment variable all emails sent will have their address
overridden by the specified value. This can be useful in test environments
when you want to test that the email service sends but not send to any users.

Based on [Notify docs][notify-docs] we can use
`simulate-delivered@notifications.service.gov.uk` as a means to send fake
emails to Notify. Based on [Amazon SES][ses-docs] we can use
`success@simulator.amazonses.com` to send emails through to SES (the underlying
service Notify uses at the time of writing.

The intention is to transition to using an override here while we are in the
process of experimenting with importing real data.

[notify-docs]: https://www.notifications.service.gov.uk/integration-testing
[ses-docs]: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/mailbox-simulator.html

### `EMAIL_ADDRESS_OVERRIDE_WHITELIST`

This environment variable takes a comma separated list of email addresses which
can be used to send emails to a whitelist of recipients despite the above
described whitelist existing.

This can be used to send emails to a select group of testers while the rest of
the emails are sent to a smoke test address. The intention is to use this in
the build up to launch so we can be testing real emails internally until the
switchover.

# ENV vars

### `EMAIL_ADDRESS_OVERRIDE`

By setting this environment variable all emails sent will have their address
overridden by the specified value. This can be useful in test environments
when you want to test that the email service sends but not send to any users.

Based on [Notify docs][notify-docs] we can use
`simulate-delivered@notifications.service.gov.uk` as a means to send fake
emails to Notify. Based on [Amazon SES][ses-docs] we can use
`success@simulator.amazonses.com` to send emails through to SES (the underlying
service Notify uses at the time of writing.

[notify-docs]: https://www.notifications.service.gov.uk/integration-testing
[ses-docs]: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/mailbox-simulator.html

### `EMAIL_ADDRESS_OVERRIDE_WHITELIST`

This environment variable takes a comma separated list of email addresses which
can be used to send emails to a whitelist of recipients despite the above
described override existing.

This can be used to send emails to a select group of testers while the rest of
the emails are sent to a smoke test address.

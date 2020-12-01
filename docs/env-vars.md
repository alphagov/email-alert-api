# ENV vars

### `GOVUK_NOTIFY_RECIPIENTS`

This environment variable determines whether emails will be attempted to be
sent to Notify. Emails that aren't send to Notify are written to a log file.
This makes this setting useful in non-production environments where you may
want to send no, or only a few emails, to Notify.

When this is set to `*` all emails are sent to Notify, this is the expected
configuration for a production environment.

In other environments this can be set as a comma separated list of email
addresses to specify the recipients who should have their emails sent to
Notify. For example, `GOVUK_NOTIFY_RECIPIENTS=test-1@example.com,test-2@example.com`.
Emails that are sent to other recipients will not be sent and will instead
be written to the log file.

If this environment variable is not set then no emails will be sent to Notify
and all will be written to the log file.

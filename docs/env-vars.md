# ENV vars

### `GOVUK_NOTIFY_RECIPIENTS`

This environment variable determines whether emails will be attempted to be
sent to Notify. Emails that aren't sent to Notify are written to a log file.
This makes this setting useful in non-production environments where you may
want to send no, or only a few emails, to Notify.

When this is set to `*` all emails are sent to Notify, this is the expected
configuration for a production environment.

In other environments this can be set as a comma separated list of email
addresses to specify the recipients who should have their emails sent to
Notify. For example, `GOVUK_NOTIFY_RECIPIENTS=test-1@example.com,test-2@example.com`.
This needs to be [set in govuk-helm-charts](https://github.com/alphagov/govuk-helm-charts/blob/948ddd80fe7a09482c532a73507a455790c47eac/charts/app-config/values-integration.yaml#L1069-L1070),
as well as be included in [Notify's guest list](https://www.notifications.service.gov.uk/services/b5213d78-8e54-4e76-8c0c-0adba7670579/api/guest-list).
Emails that are sent to other recipients will not be sent and will instead
be written to the log file.

If this environment variable is not set then no emails will be sent to Notify
and all will be written to the log file.

### `ALERT_LISTENER_EMAIL_ACCOUNT`

This environment variable is used to set which email address will receive copies of sent medical/travel alerts and it is configured in govuk-helm-charts. See [this config for Production](https://github.com/alphagov/govuk-helm-charts/blob/948ddd80fe7a09482c532a73507a455790c47eac/charts/app-config/values-production.yaml#L1010-L1011) as an example.

In Integration they are sent to the [Email Alert API Integration](https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-integration) Google Group, and in Staging they are sent to the [Email Alert API Staging](https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-staging) Google Group.

In Production this is the [Email Alert API Alert Listener](https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-alert-listener) Google Group.

### `BULK_MIGRATE_CONFIRMATION_EMAIL_ACCOUNT`

This environment variable is used to set which email address will receive confirmation emails when the [data_migration:move_all_subscribers rake task](https://github.com/alphagov/email-alert-api/blob/f79ae54ebf6542434c9ec4fadae404f4c899cbaa/lib/tasks/data_migration.rake#L5) is run. It is configured in `govuk-helm-charts`, see [this config for Production](https://github.com/alphagov/govuk-helm-charts/blob/main/charts/app-config/values-production.yaml#L1012-L1013) as an example.

In Integration they are sent to the [Email Alert API Integration](https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-integration) Google Group, and in Staging they are sent to the [Email Alert API Staging](https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-staging) Google Group.

In Production this is the [Email Alert API Bulk Migrate](https://groups.google.com/a/digital.cabinet-office.gov.uk/g/email-alert-api-bulk-migrate/) Google Group.
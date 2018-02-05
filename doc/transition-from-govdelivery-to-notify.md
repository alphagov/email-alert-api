# Transition from Govdelivery to Notify

This document serves as documentation for the transition from Govdelivery to
Notify as the means to send emails. The intention is that this stores
information related to the migration and this app close to the codebase.
It will be safe to remove this once the migration has been completed.

## ENV vars

### `DISABLE_GOVDELIVERY_EMAILS`

By setting a value for this notification changes will no longer be sent to
govdelivery. This is set within the [app/notifications_worker.rb][worker].

When this is set jobs will still be scheduled to sidekiq but they will all not
be executed. No data will be saved about jobs aborted.

[worker]: ../app/notifications_worker.rb

### `USE_EMAIL_ALERT_FRONTEND_FOR_EMAIL_COLLECTION`

When this environment variable set the redirect location that is returned
as part of a subscriber list JSON serialization. Once this is returning
frontend apps will redirect users to the Email Alert Frontend signup which
does not use govdelivery.

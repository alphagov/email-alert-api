# Support tasks

Users can manage email subscribers via the [administration interface on GOV.UK][email-manage].
Support tickets coming through to 2ndline where the user is unaware of this,
or needs guidance, can be assigned to "2nd Line--User Support Escalation".

> **Note**
>
> This applies only to emails sent by GOV.UK.
> [Drug safety updates][drug-updates] are sent manually by MHRA, who manage
> their own service using Govdelivery. We do not have access to this.

If it is not possible for changes to be managed by the user, it is
possible for changes to be made manually. The following rake tasks
should be run using the Jenkins `Run rake task` job for ease-of-use:

[email-manage]: https://www.gov.uk/email/manage
[drug-updates]: https://www.gov.uk/drug-safety-update

## Change a subscriber's email address

This task changes a subscriber's email address.

```bash
$ bundle exec rake support:change_email_address[<old_email_address>, <new_email_address>]
```

[⚙ Run rake task on production][change]

[change]: https://deploy.blue.production.govuk.digital/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=support:change_email_address[from@example.org,to@example.org]

## View subscriber's recent emails

This task shows the most recent emails for the given user.
It takes two parameters: `email_address` (required), and `limit` (optional).
`limit` defaults to 10, but you can override this if you need to see more of
the user's history.

```bash
$ bundle exec rake support:view_emails[<email_address>,<limit>]
```

[⚙ Run rake task on production][view_emails]

[view_emails]: https://deploy.blue.production.govuk.digital/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=support:view_emails[email@example.org]

## View subscriber's subscriptions

This task shows you all of the active and inactive subscriptions for a given user.

```bash
$ bundle exec rake support:view_subscriptions[<email_address>]
```

[⚙ Run rake task on production][view]

[view]: https://deploy.blue.production.govuk.digital/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=support:view_subscriptions[email@example.org]

## Unsubscribe a subscriber from a specific subscription

This task unsubscribes one subscriber from a subscription, given an email address and a subscriber list slug.
You can find out the slug of the subscriber list by running the `view_subscriptions` rake task. above

```bash
$ bundle exec rake support:unsubscribe_single_subscription[<email_address>,<subscriber_list_slug>]
```

[⚙ Run rake task on production][unsub_specific]

[unsub_specific]: https://deploy.blue.production.govuk.digital/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=support:unsubscribe_single_subscription[email@example.org,subscriber-list-slug]

## Unsubscribe a subscriber from all emails

This task unsubscribes one subscriber from everything they have subscribed to.

```bash
$ bundle exec rake support:unsubscribe_all_subscriptions[<email_address>]
```

[⚙ Run rake task on production][unsub]

[unsub]: https://deploy.blue.production.govuk.digital/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=support:unsubscribe_all_subscriptions[email@example.org]

## Send a test email

To send a test email to an email address (doesn't have to be subscribed to anything):

```bash
$ bundle exec rake support:send_test_email[<email_address>]
```

## Resend failed emails

There are two Rake tasks available to resend emails which didn't send for
whatever reason and ended up in the failed state. This is most useful after
an incident to resend all emails that failed with a technical failure.

### Using a date range

```bash
bundle exec rake 'support:resend_failed_emails:by_date[<from_date>,<to_date>]'
```

The date format should be in ISO8601 format, for example `2020-01-01T10:00:00Z`.
Depending on the number of emails to send, the Rake task can take a few minutes to run.

### Using email IDs

```bash
bundle exec rake 'support:resend_failed_emails:by_id[<email_one_id>,<email_two_id>]'
```

## Get subscriber list csv report

To see a csv report for the number of subscribers for a given list:

```bash
bundle exec rake 'report:csv_subscriber_lists[<on_date>] SLUGS=<list_slug>'
```

The date should be in ISO8601 format, for example 2020-01-01.

## Get a simple count of subscribers to a list by its URL

To see a simple count of the number of subscribers for a given list:

```bash
bundle exec rake 'report:csv_subscriber_lists[<url>]'
```
This will always report on the number of active subscriptions for a given url, as of the end of today.

You can also pass it a :active_on_datetime which will count how many active subscriptions there were at the end of the day on a particular date.
(active is defined as created before that datetime and not with an "ended_on" datetime by the given date)

You can run the task on Jenkins with the following links:

- [Integration](https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:subscriber_list_subscriber_count[%22%3Cpage_path_here%3E%22]) - Only really useful for testing
- [Staging](https://deploy.blue.staging.govuk.digital/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:subscriber_list_subscriber_count[%22%3Cpage_path_here%3E%22]) - Data will be a snapshot from last replication
- [Production](https://deploy.blue.production.govuk.digital/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:subscriber_list_subscriber_count[%22%3Cpage_path_here%3E%22]) - Live data

```bash
bundle exec rake 'report:csv_subscriber_lists[<url>, <active_on_date>]'
```

The active_on_date should be in ISO8601 format, for example 2022-03-03T12:12:16+00:00.
The time will always be rounded to the end of the day, even if that is in the future.

## Get a report of single page notification subscriber lists by active subscriber count

This report provides a count of all subscriber lists with a content ID, followed by individual subscriber lists ordered by active subscriber count.

```bash
bundle exec rake 'report:single_page_notifications_top_subscriber_lists'
```

By default output is limited to only show the top 25 lists by active subscriber count. However
that can be overridden to increase or decrease the output number.

```bash
bundle exec rake 'report:single_page_notifications_top_subscriber_lists[5]'
```

You can run the task on Jenkins with the following links:

- [Integration](https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:single_page_notifications_top_subscriber_lists) - Only really useful for testing
- [Staging](https://deploy.blue.staging.govuk.digital/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:single_page_notifications_top_subscriber_lists) - Data will be a snapshot from last replication
- [Production](https://deploy.blue.production.govuk.digital/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:single_page_notifications_top_subscriber_lists) - Live data

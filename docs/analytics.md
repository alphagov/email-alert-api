# Analytics

Email Alert API does not currently have many automated means to generate
analytics and data insights. This document serves as a guide to understand
how to produce this information.

## Available data

We retain most data the system doesn't use for one year. This is outlined in
the [data retention strategy] for Email Alert API. We do have a couple of
exceptions to this: emails are removed 7 days after they are sent and subscriber
lists that have never had a subscriber are also removed after 7 days.

In addition we [nullify subscriber's email addresses] that have been
unsubscribed from all subscriptions for more than 28 days. This is carried out
so we don't store user's personal information for longer than needed.

[data retention strategy]: https://github.com/alphagov/email-alert-api/blob/master/docs/adr/adr-007-retain-data-for-up-to-one-year.md#decision
[nullify subscriber's email addresses]: https://github.com/alphagov/email-alert-api/blob/master/docs/data-cleanup-mechanisms.md#nullifying-email-addresses

## Analytics through Rake tasks

A large number of analytic insights can be discovered by working with the
[database schema][schema.rb] and querying the data. The intention is that when
useful common queries are identified they will be made accessible via rake tasks.

[schema.rb]: https://github.com/alphagov/email-alert-api/tree/master/db/schema.rb

### Count subscriptions to a subscriber list

This shows subscription counts by Immediate, Daily or Weekly:

```bash
rake report:count_subscribers['subscriber-list-slug']
```

[⚙ Run rake task on Integration][rake-count-subscribers]

[rake-count-subscribers]: https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:count_subscribers['subscriber-list-slug']

If you need to know the number of subscriptions on a particular day:

```bash
rake report:count_subscribers_on[yyyy-mm-dd,'subscriber-list-slug']
```

[⚙ Run rake task on Integration][rake-count-subscribers-on]

[rake-count-subscribers-on]: https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:count_subscribers_on[yyyy-mm-dd,'subscriber-list-slug']

### Content changes for each subscriber list

This generates a CSV report of matched content changes over the last week.

```bash
rake report:matched_content_changes

# or with a specific range
START_DATE=2020-08-07 END_DATE=2020-08-13 rake report:matched_content_changes
```

[⚙ Run rake task on Integration][rake-matched-content-changes]

[rake-matched-content-changes]: https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:matched_content_changes

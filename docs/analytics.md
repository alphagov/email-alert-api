# Analytics

Email Alert API does not currently have many automated means to generate
analytics and data insights. This document serves as a guide to understand
how to produce this information.

## How data is organised

Most of the data in this application is stored in the database for perpetuity,
thus for most cases querying the database through Rails console or through
PostgreSQL is appropriate. However as this application creates such a large
volume of emails these are instead archived with minimal data in
[Amazon S3](https://aws.amazon.com/s3/) and can be queried
with [Amazon Athena][athena].

Once an email has been sent or is no longer being sent (such as a
permanent failure) the record will be archived in a reduced form and sent to
Amazon S3 in hourly batches. After 14 days the email will be removed from the
database. Thus for recent information the `emails` database table can be used
otherwise the email archive should be queried.

## Analytics through Rake tasks

A large number of analytic insights can be discovered by working with the
[database schema][schema.rb] and querying the data. The intention is that when
useful common queries are identified they will be made accessible via rake tasks.

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

## Analytics through Athena

[Athena][athena] is accessible through the AWS control panel which can be
accessed by following the [instructions][console-instructions] provided in the
developer docs. To access the production data you will need to use the
`govuk-infrastructure-production` account, once there you can head to
[athena](https://eu-west-1.console.aws.amazon.com/athena) and select the
`email_alert_api_archive` database.

The data stored in Athena is the email id; when the sending process completed;
whether the email sent; the email subject of the email; the associations to
content change and digests; and timestamps for when the email was created and
archived. The data is arranged by partitions of the date when the email
finished sending - **It is vastly cheaper and faster to query with
[partitions](#always-query-with-partitions)**.

Querying Athena is done through a SQL dialect provided by
[presto](https://prestodb.io/) - query [documentation][athena-queries] is
available.

### Always query with partitions

You should always query with a where condition which defines the partitions
to be used in your result set e.g. `WHERE year=2018 AND month=7 AND date=4`
unless you are sure you need a wider data range.

The data is stored in directories which separate the data by year, month and
date values. By applying a partition to the query, such as `WHERE year=2018 AND
month=7 AND date=4` you reduce the data needed to be traversed in the query
to just the files from that single day. Which naturally makes the query
perform substantially quicker.

Each query against Athena has a
[monetary cost](https://aws.amazon.com/athena/pricing/) - at time of writing $5
per TB of data scanned - and by using partitions you massively reduce the data
that needs to be scanned.

### Example queries

#### Look up emails sent/failed on a particular day

```sql
SELECT sent, count(*) AS count
FROM "email_alert_api_archive"."email_archive"
WHERE year = 2018 AND month = 7 AND date = 4
GROUP BY sent;
```

#### Look up an email by id

```sql
SELECT *
FROM "email_alert_api_archive"."email_archive"
WHERE id = 'fc294e14-3b09-4869-ab07-a5c72ed04a01'
AND year = 2018 AND month = 7 AND date = 5;
```

#### Look up emails associated with a content change

```sql
SELECT *
FROM "email_alert_api_archive"."email_archive"
WHERE CONTAINS(content_change.content_change_ids, 'bfd76384-1a1d-4da8-bc65-a79d9cb270d6')
AND year = 2018 AND month = 7
LIMIT 10;
```

#### Count emails a subscriber was sent per subscription for a time period

```sql
SELECT content_change.subscription_ids, COUNT(*) AS count
FROM "email_alert_api_archive"."email_archive"
WHERE subscriber_id = 4840
AND content_change.digest_run_id IS NULL
AND sent = true
AND year = 2018
GROUP BY content_change.subscription_ids
ORDER BY count DESC
LIMIT 10;
```

[athena]: https://aws.amazon.com/athena/
[athena-queries]: https://docs.aws.amazon.com/athena/latest/ug/functions-operators-reference-section.html
[aws]: https://aws.amazon.com
[console-instructions]: https://docs.publishing.service.gov.uk/manual/seeing-things-in-the-aws-console.html
[schema.rb]: https://github.com/alphagov/email-alert-api/tree/master/db/schema.rb
[support-tasks]: /apis/email-alert-api/support-tasks.html#count-subscriptions-to-a-subscriber-list

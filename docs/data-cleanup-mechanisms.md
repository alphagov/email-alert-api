# Data cleanup mechanisms

There are several mechanisms regarding the cleanup of data in Email Alert Api.
This doc gives an overview of each.

## Nullifying email addresses

Updates the `address` of old unsubscribed `Subscriber` records to `nil`. We do
this to comply with GDPR, specifically so we're not retaining user's data for
longer than needed.

We nullify subscribers in two different scenarios.

Firstly, once they've been unsubscribed from all subscriptions for over 28
days. We could nullify user's email addresses immediately after unsubscribing
but this would limit our ability to assist in user support queries. E.g.
restoring a user's subscriptions after they've unsubscribed by accident which
would be impossible to do if the system had nullified their address
immediately after unsubscribing.

Secondly, subscribers are nullified which are created more than 28 days ago and
don't have any subscriptions at all (active or ended). It shouldn't be possible
for subscribers to exist without subscriptions but these are queried and
removed anyway to prevent storing user's data indefinitely if, for whatever
reason, a subscriber ends up with no subscriptions. This has happened before,
unintentionally, see [here][sub bug] and [here][sub bug two].

The [NullifySubscribersJob] runs [every hour].

[every hour]: https://github.com/alphagov/email-alert-api/blob/main/config/sidekiq.yml#L36
[NullifySubscribersJob]: https://github.com/alphagov/email-alert-api/blob/main/app/jobs/nullify_subscribers_job.rb
[sub bug]: https://github.com/alphagov/email-alert-api/pull/1462/commits/053859c5962eef104256661f28727b08a43e3d31
[sub bug two]: https://github.com/alphagov/email-alert-api/pull/1462/commits/a4b3e82801d79abd3989b1dd60ffd499e7ce82ba

## Deleting emails

The [EmailDeletionJob] deletes emails after 7 days. These recently archived
emails get deleted regularly to keep the database performant as we produce a
large quantity which the system only uses for a short period of time. In deleting
these emails we also delete their associated subscription contents through a
[db cascade]. As of 05/11/2020 we generate around ~3 million emails per day.

The [deletion job] runs every hour. Every hour was chosen to limit the worst
case backlog (and potential performance impact) if a run of the job fails for
transient reasons. Note that it often takes 10-30 minutes just to delete an hour's
worth of email, so it's not feasible to run this job more frequently.

[deletion job]: https://github.com/alphagov/email-alert-api/blob/main/config/sidekiq.yml#L39
[EmailDeletioJob]: https://github.com/alphagov/email-alert-api/blob/main/app/jobs/email_deletion_job.rb
[db cascade]: https://github.com/alphagov/email-alert-api/blob/11fb84542e6c7f3995f419e4affaf56aa759ec6c/db/schema.rb#L206

## Deleting historic data

The [HistoricalDataDeletionJob] deletes data we deem as historic everday at
[midday]. Midday was chosen as removing historic data is deemed non urgent work
and so running once a day, in hours, seems sufficient.

In general, we remove historic, unused data after a year. One exception to this
is that we remove subscriber lists which have been created over seven days ago
and never had any subscriptions.

We remove this data so we don't pollute our analytics or run into future
capacity issues.

You can read in more detail about the decision to implement the historic
deletion of data in [ADR-7].

[midday]: https://github.com/alphagov/email-alert-api/blob/main/config/sidekiq.yml#L33
[HistoricalDataDeletionWorker]: https://github.com/alphagov/email-alert-api/blob/main/app/jobs/historical_data_deletion_job.rb
[ADR-7]: https://github.com/alphagov/email-alert-api/blob/master/docs/adr/adr-007-retain-data-for-up-to-one-year.md#decision

# Troubleshooting

## How email sending is triggered by content changes

We attempt to send emails to subscribers when content changes if they have a subscription for a subscribable that matches.

A change to a content item creates a `ContentChange` record, which has a `SubscriptionContent` that belongs to an `Email`. The `SubscriptionContent` is linked to a `Subscription`, which has a `Subscriber`, and belongs to a `Subscribable`. A `DeliveryAttempt` is made on the `Email`.

![domain](https://github.com/alphagov/email-alert-api/blob/master/doc/domain.png?raw=true)

## The digest run workflow

A daily task (for the daily digest) or a Monday task (for the weekly digest) runs as a scheduled task in the `DigestInitiatorService`. This creates a `DigestRun`, then fetches the IDs of the subscribers and creates a `DigestRunSubscriber` record for each one, before enqueuing the digest run subscribers in the `DigestGenerationWorker`.

This worker uses a `SubscriptionContentChangeQuery` to fetch subscriptions with content changes, and creates an `Email` using the `DigestEmailBuilder` and composed of `SubscriptionContent`.

![digests](https://github.com/alphagov/email-alert-api/blob/master/doc/digests.png?raw=true)

## Fixing "PG::InsufficientPrivilege" error in the development VM

email-alert-api relies on PostgreSQL's `uuid-ossp` module. This is not
available by default and you might find running migrations results in
the following error:

```
PG::InsufficientPrivilege: ERROR:  permission denied to create extension "uuid-ossp"
```

This can be solved by:

```bash
> sudo -upostgres psql email-alert-api_development
psql> CREATE EXTENSION "uuid-ossp";
```

and then repeating for `email-alert-api_test`.

## Manually retrying failed notification jobs

In the event of an outage, the Email Alert API will enqueue failed
notification jobs in the Sidekiq retry queue. The retry queue size
can be viewed via Sidekiq monitoring or by running the following
command in a rails console:

```ruby
Sidekiq::RetrySet.new.size
```

To manually retry all jobs in the retry queue:

```ruby
Sidekiq::RetrySet.new.retry_all
```

See the [Sidekiq docs](https://github.com/mperham/sidekiq/wiki/API)
for more information.


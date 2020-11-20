# 7. Retain data for up to one year

Date: 2020-11-19

## Context

The original ADR concerning data retention resides [here][initial policy] and
outlines our approach from February 2018. At that point in time it was decided
we should retain all data in Email Alert Api with the exception of
emails which are [archived] to S3 & [deleted] after a week.

Since then we've come to realise that a revision of our data retention policy
is needed as we're generating more data that will never be used again - by us,
or the system.

This was initially prompted by recent work to [migrate subscribers to daily
digest emails] which lead to an increase in the amount of unmanaged data we
produce and store locally in Email Alert Api. Consequently, this provoked worries
that perpetually keeping data could result in capacity issues due to the rapid
increase in data being stored. An example being we now generate ~430,000
`DigestRunSubscriber` records each day which is about eight times the amount
compared to that of ten months ago.

We've also gained more insight into what data we're not using for analytics.
The original plan documented in the previous retention policy was to retain as
much data as possible to enable us to do as much analysis as needed in the
future. However, much of this data is never used for analysis and so doesn't
serve a purpose in the email system.

Contrary to what was previously thought, storing lots of unused data
indefinitely actually complicates and pollutes our auditing and analysis. An
example of this can be seen if we look at subscriber lists. We have over
~73,000 lists with active subscribers but in the last week alone, we've
accumulated 1139 lists which don't have any subscriptions at all (ended or
active). These unused lists prevent us from doing simple auditing tasks
easily, like finding which lists to report on.

Knowing the above, we thought about how we could clean-up this unused data to
keep Email Alert Api's database manageable going forward. There are a couple of
different approaches to consider, including storing unused data in cloud
storage away from the system's database (like we do when archiving emails) and
subsequently deleting the data locally. Or, setting up a means of removing the
data we don't use from the system entirely.

[archived]: https://github.com/alphagov/email-alert-api/blob/master/app/workers/email_archive_worker.rb
[deleted]: https://github.com/alphagov/email-alert-api/blob/master/app/workers/email_deletion_worker.rb
[initial policy]: https://github.com/alphagov/email-alert-api/blob/master/docs/adr/adr-003-data-retention.md
[migrate subscribers to daily digest emails]: https://github.com/alphagov/email-alert-api/pull/1352

## Decision

We decided that historic, unused data should be removed periodically from the
system entirely. It was concluded that the data the system no longer uses
should only exist for a maximum of 1 year before removal. We sometimes
analyse historic data from up to a year ago but we have no evidence of needing
this data for analytics beyond a year.

The following list documents our approach to the decision for different data
in the system.

* **ContentChange, Message & DigestRun**. Remove once their `created_at` value is
  over a year old.

* **MatchedContentChange, MatchedMessage & DigestRunSubscriber**. Removed
  automatically when their parent ContentChange/Message/DigestRun is
  deleted.

* **Subscription**. Remove subscriptions when they've been ended for over a
  year, based on their `ended_at` value. Once a subscription is ended it [can't
  currently be made active again] and so can be deleted.

* **Previously subscribed to SubscriberList**. Remove lists when they have no
  active subscriptions and their latest, ended subscription is over a year old.
  It is possible for a list we deem as historic to be subscribed to again,
  however this seems unlikely due to the list not having any active
  subscriptions for over a year.  If this was to happen, after the list has
  been deleted then a new `SubscriberList` record will be generated.

* **Unused SubscriberList**. Remove lists which have never had any
  subscriptions and are over 7 days old. A scenario of when this can happen is
  when a user quits their signup journey midway through. 7 days was the chosen
  retention period to allow users to complete their signup journey as they have
  a [7 day limit] to confirm their subscription. As mentioned in the context
  section, unused subscriber lists pollute our analytics and so we should
  remove them regularly.

* **Subscriber**. Remove subscribers once their `created_at` is over a year old
  and they don't have any subscriptions (active or ended). Subscribers should
  only be without subscriptions when their historic subscriptions have been
  deleted. This means we should be able to delete all subscribers (under a year
  old too) that don't have any subscriptions. However, we don't delete these
  subscribers to prevent us from removing new subscribers that lack
  subscriptions, due to flaws in our code.  Some examples of where it was
  unintentionally possible to end up with subscribers with no subscriptions can
  be found [here][sub bug] and [here][sub bug two].

Emails (and their associated SubscriptionContents) are the one place where we
already manage retention - these are held locally for 7 days, and also
archived to Athena indefinitely. We still need this low retention for Emails in
order to manage the size of the table. However, the archiving to Athena is
inconsistent with the above decision to delete unused data entirely. While we
originally thought Athena might serve as a data source for analytics, this has
not happened in practice, so the archive data stored there is entirely unused.
We therefore decided to remove the archiving mechanism for Emails, since it has
no value.

[can't currently be made active again]: https://github.com/alphagov/email-alert-api/blob/master/docs/adr/adr-003-data-retention.md#subscriber-and-subscription
[7 day limit]: https://github.com/alphagov/email-alert-api/blob/f0c61539f7244bdb52db54d277a46412b728d642/app/services/auth_token_generator_service.rb#L7

## Status

Accepted

## Consequences

### Historic deletion worker

We implemented a [worker] which runs periodically every day at [midday].
Removing this data was deemed as non urgent and so deleting once a day, in
hours, seemed sufficient.

### The first historic deletion run

On the first run of the worker which handles deleting historical data we
removed over 33 million records. A breakdown of the amount of deletions per
model can be found below:

* ContentChange - 148,617

* MatchedContentChange - 1,825,983

* Message - 15

* MatchedMessage - 16,099

* DigestRun - 677

* DigestRunSubscriber - 30,858,770

* Subscription - 1,046,576

* SubscriberList - 11,470

* Subscriber - 196,376

### Restrict analytics to 1 year of unused data

We now restrict our unused data for analytics to a period of at most 1 year.
This means any queries looking for this data (e.g. ended subscriptions over a
year old) will be met with no results. We don't expect this to be an issue due
to our current expectation of the data we'll need for future analytics.

### Modify the nullify process and retire the deactivated concept

When documenting our data retention policy as described in this ADR, we found
it difficult to understand and document the tangential concept of [deactivating
and nullifying] subscribers.

To give some context on these concepts:

* Nullifying subscribers means to update the `address` of `Subscriber` records
  to `nil` which have been unsubscribed from all subscriptions, for more than
  28 days.

* Deactivating subscribers is a concept that revolves around the
  `deactivated_at` field on the subscriber model. This field is populated when
  a subscriber unsubscribes from their last active subscription. It is used as
  a means to determine when a subscriber can be nullified.

We can however obtain the information held within `deactivated_at` through the
`ended_at` field of the most recent ended subscription of an unsubscribed
user, meaning the deactivated concept is superfluous.

Subsequently we didn't want to spend energy documenting a process that didn't
make much sense to begin with so it was decided that it would be easier (and
beneficial as a whole) to just [remove] the deactivated concept completely.

In removing the deactivated concept we [modified the nullify process] to use
`ended_at`, as described above, instead of `deactivated_at`. We also updated
the process to nullify subscribers which have no subscriptions (active or
ended) and are older than 28 days. This prevents the system from storing user's
personal data longer than needed, if for whatever reason, a subscriber is
created without any subscriptions. See examples of where this happened
[here][sub bug] and [here][sub bug two].

### Deprecate archiving Email to Athena

We have planned work to remove it in the future. In the meantime, we consider
archiving to Athena to be deprecated, and have updated [the documentation around
it] to reflect this status.

[modified the nullify process]: https://github.com/alphagov/email-alert-api/pull/1462/commits/cefdfa76b13915ea96b131490fd3186b6d52cf05
[remove]: https://github.com/alphagov/email-alert-api/pull/1462
[sub bug]: https://github.com/alphagov/email-alert-api/pull/1462/commits/053859c5962eef104256661f28727b08a43e3d31
[sub bug two]: https://github.com/alphagov/email-alert-api/pull/1462/commits/a4b3e82801d79abd3989b1dd60ffd499e7ce82ba
[midday]: https://github.com/alphagov/email-alert-api/blob/master/config/sidekiq.yml#L23-L25
[worker]: https://github.com/alphagov/email-alert-api/blob/a62abc85453b723d683c2dc13f3bf0065fb86d5f/app/workers/historical_data_deletion_worker.rb
[deactivating and nullifying]: https://github.com/alphagov/email-alert-api/blob/master/docs/adr/adr-003-data-retention.md#subscriber-and-subscription
[the documentation around it]: https://github.com/alphagov/email-alert-api/blob/1a25d44126709bf8a98955d7609ced439095dd9c/docs/analytics.md

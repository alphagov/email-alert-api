# Decision Record: Initial Data Retention Strategy

> **Note**
> The data retention strategy was revisited in [ADR-7] which supersedes this decision.

[ADR-7]: https://github.com/alphagov/email-alert-api/blob/master/docs/adr/adr-007-retain-data-for-up-to-one-year.md

## Introduction

In February 2018, prior to switching from Govdelivery to Notify we wished to
consider our approach to data retention in such a way to enable data driven
decisions in the future.

The aim in this work is to make suggestions that enable a comparable amount of
data to what is currently used by Govdelivery and for that data to be
flexible. This is balanced against the constraint that Email Alert API does
produce a lot of data and this should be culled regularly to not use too much
disk space without justification. It also intends to do this with respect to
the constraints of GDPR by not storing personally identifiable data for
longer than is needed.

The goal being that we can complete this prior to the change to Notify so that
we avoid a data black hole where we do not have the data to answer common
data queries.

## Specifics

### Common data use scenarios

Based on a chat with Paul (our performance analyst) we were demonstrated to a
number of scenarios of data look ups and usage. As this was only a short session
this list is likely incomplete.

#### Data that is currently looked up

- Number of people subscribed to list
  - Given a date range: how many people subscribed in that range; how many
    unscribed; total number of subscribers during that time period.
- Activity Level of list
  - Given a date range: how many emails were sent out to that list; how many
    bulletins a list has associated with it; how many emails a list has
    genertaed; whether lists have never produced an email.
- Overall totals
  - Counts of how many emails we have sent over a specific period of time or
    total (mostly used internally)

#### Support queries

- People have been unsubscribed and don’t know why (Govdelivery tracks a user
  unsubscribed but not which lists)
- Why a user was unsubscribed - this can happen automatically or a user
  performs the action.
- Occasional need to check email. Reason this can happen is that we get a query
  because the link may not be working, so we would look at what was sent.

#### Things that would be useful

- Knowing difference between users who subscribed by themselves or were
  imported (our initial data import will leave us with inconsistent stats)
- Ability to recreate subscriptions when people have unsubscribed.

### Suggested Changes

This is a summary of a collection of changes to the data architecture to enable
most statistical data to be retained at a relatively low level of pain of
implementation and should enable future decisions to be made about usage and
storage with a relatively full set of data.

#### Email and DeliveryAttempt

The largest source of data is the Email table which has a relationship with
DeliveryAttempt. This is the most pressing problem to resolve in terms of
data retention as this quickly builds up a substantial quantity of data.

The suggested approach to dealing with this is to have two separate
processes which can both be adjusted as we learn more about the system.

The first of these processes is an archiving one which should happen within
24 hours of an email reaching a final state (either sent or failed). When this
has occurred the row should be marked that as archived (suggestion is for a
`archived_at` timestamp) so it not as archived again and is known to be safe
to delete later.

The archiving would not involve any personally identifiable data and would
only include the subject field from the email. As an example:

```
{
  "id": "5c59b695-dbaa-4291-9e25-5024dcbfb45d",
  "subject": "Test email",
  "subscriber_id": 43, // or null
  "content_change": { // or null
    subscription_ids: [45], // array of subscriptions this email is associated with
    content_change_ids: [32], // array of content_changes this email is associated with
    digest_id: 10 // or null
  },
  created_at: date,
  completed_at: date,
  final_status: "sent",
  // maybe include delivery attempt information
}
```

Ideally this data would be stored in S3, but as an interim the suggestion is to
store this in an `email_archives` database table which can then be exported to
S3 when we have the time/resources available to configure that association.

The second process would be the deletion of the emails (which would also remove
the related delivery attempts). This would be removed after a period of 14 days
after the email process completed. This period is determined thus to allow
sufficient time for a support ticket to come in and a small investigation to
occur.

Since the deletion process is decoupled from the archive one the time can
be adjusted based on data needs.

An additional change to these tables will be to replace their ids with uuid
datatypes. This will allow us to remove the reference field of
`delivery_attempt` - which seems to be created as a psuedo uuid value
combining a database id and a timestamp. The reason for changing email to be a
uuid is to have this as a value that is globally unique and can be used as a
further reference without revealing system information.

#### SubscriptionContent

SubscriptionContent is currently the glue that holds together the association
between a ContentChange, a Subscription, a resulting Email and a
DigestRunSubscriber. Currently when an email is deleted there is a cascade
to set the value to SubscriptionContent to null. This is incorrect as the value
of null here indicates an email is scheduled to be generated. Instead this
foreign key should be set to have an on delete cascade association with Email
so that when an email is removed from the system the proceeding
SubscriptionContent values are also deleted.

This will mean that over time the data in the SubscriptionContent will be
culled routinely as part of the Email deletion process.

#### DigestRun and DigestRunSubscriber

Currently we store each DigestRun and an association to each subscriber. If we
want to know how many subscribers were due to be emailed about a digest we can
count the number of DigestRunSubscibers associated.

As the number of subscribers related with a digest is something that is known
at the point of digest creation we can store this as a count on
DigestRun. This can alleviate the need for storing each DigestRunSubscriber
(which can be removed at approximately the same interval as Emails).

As DigestRuns are low on data usage they can effectively be stored indefinitely
or at least until we determine an approach to archiving them.

#### ContentChange and SubscriptionList

Both ContentChange and SubscriptionList should not require changes to them in
order to allow us to build up a full analytics picture. However they would
require an intention not to delete either of them.

Despite this a small change is suggested for ContentChange to switch the
primary key type from being an auto-incrementing number to a uuid. This is to
allow this to be sent out as part of analytics tracking without revealing state
or ordering information of the underlying system.

As a SubscriberList can be updated the only way we can determine the historical
number of ContentChanges with accuracy is to have the ContentChanges
available (to perform the look up between them).

It is likely that over time ContentChanges may reach an infeasible number and
it will then need to be looked at as to what value storing them maintains, but
hopefully by that point (expected to be a couple of years away) we'll have a
much firmer understanding of the analytics usage and needs.

SubscriptionLists don't currently have the ability to be deleted by apps, and
it's likely if they gained that ability that would need to be some form of
archiving so it could still be communicated to users that the list they had a
subscription to is no longer available.


#### Subscriber and Subscription

Previously when a subscription ended they would be deleted and when the last
subscription was removed the subscriber would have an address nullified. This
was later iterated to using a temporary soft delete on subscriptions to not
remove them while we worked out whether they have a long term value.

By looking at the use cases and support queries we've been able to determine
that is useful to store both sets of data indefinitely and that it would be
useful for support queries to not remove the email address until after a
reasonable support window for diagnostic purposes.

A field would be added to subscriber of `deactivated_at` which would be used to
determine whether a subscriber is activated. Once a Subscriber has been
deactivated for 28 days any personal information will be removed from the
account. Any additional activity on the account will cause the account to be
reactivated.

_Aside: The `deactivated_at` field may not be required it could be determined
by the lack of any active subscriptions. It just might be useful to have this
as queries regarding end of a subscriber would be complex without it._

This 28 day window is intended to provide us with sufficient time that we can
deal with any support queries that occur due to account issues (as this is a
reasonably regular occurance).

With subscriptions the intention is to use this as an append only table and
any change to a subscription (starting, ending, change of frequency) creates
a new entry into this table. There will however be an active flag which can be
used as part of the unique index on this to ensure a user can only have one
active subscription at a time. This exception would not make it fully append
anly.

An additional change will be to rename the `deleted_at` field to `ended_at`, as
it is used to record the time that the subscription ended at. The purpose of
this field is to enable queries which determine the number of subscriptions at
particular time periods. Additionally the suggestion is to include fields of
the source of creating the subscription and to include the reason the
subscription was ended.

Finally we have a uuid field stored on subscription, it would likely be better
for us to have a primary key that is the uuid and then not have a second
numerical id.

### Summary of database changes

#### Email

- Change the id type from a serial to a uuid
- Add an archived_at timestamp
- Would be removed from database after 14 days

#### EmailArchive

- A table which is store abridged Email data with the intention of this moving
  to S3 (or a different data analytics storage)
    - On this store information such as id, subject, subscriber_id,
      content_changes (see example above)
    - Store no personally identifiable information

#### DeliveryAttempt

- Change id to a uuid
- Drop reference field and use uuid instead
- Would be removed (as part of a cascade with Email) after 14 days

#### SubscribtionContent

- Would be deleted automatically when the corresponding Email is deleted

#### ContentChange

- Primary key should change to a uuid
- Should not be deleted, as part of analytics picture

#### SubscriberList

- Should not be deleted, as part of analytics picture

#### Subscriber

- Add a `deactivated_at` timestamp field
- Should not be deleted, as part of analytics picture

#### Subscription

- Change primary key to be a uuid
- Drop existing `uuid` field
- Replace the `deleted_at` field with an `ended_at` field.
- Create an enum field for source (ideas are imported, user_signup,
  frequency_change)
- Create an enum field for end (ideas are user_unsubscribe, non_existent_email,
  frequency_change)
- Create an active boolean field
- Drop the current unique key and replace it with one that incorporates active
- Relationship to Subscriber has an ON_DELETE of restrict to try ensure these
  can't be lost in the system
- Should not be deleted, as part of analytics picture

### Plans for future

The intention is that this strategy provides us with sufficient data stored
that we have a lot of flexibility going forward as we determine the analytics
need of Email Alert API.

The most pressing concern following implementation of this would be moving
the EmailArchive data out of the databse as that would still build up
relatively fast as a significant quantity of data (but still much lower than
Email produces)

Following this the simplest way likely to query this data would be with [Amazon
Athena][athena] (assuming it's in S3). So our queries for data could either be
to our db or a combination of data from our db and Athena.

It is likely that as the database grows though that some queries will become
slow so this strategy will require iteration once we're closer to producing
analytics and the usage of a tool such as [Amazon Red Shift][red-shift] may be
more approriate.

[athena]: https://aws.amazon.com/athena/
[red-shift]: https://aws.amazon.com/redshift/

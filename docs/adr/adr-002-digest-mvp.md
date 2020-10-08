# Decision Record: MVP implementation of Digests

## Introduction

In January 2018 we started one of the latest major pieces of functionality that
would be required to meet our MVP (minimal viable product) and allow us to
launch a Notify powered iteration of Email Alert API.

This document serves to outline the architecture we have planned for this and
explain the purposes of the individual components.

## Specifics

### Product decisions

The need for a change in architecture was determined by product decisions which
differed from the previous understanding of digest function explored in
[adr-001](adr-001-notify-integration.md).

The biggest decision that influenced the change was an intention to send each
user a single digest email that contained all of their topics as is consistent
with Govdelivery. We had previously intended to launch with the change that
each subscription is a separate email.

A change from Govdelivery is that we will store the delivery preference
(immediate, daily, weekly) at a subscription level rather than a user level.
This will mean that a user can be signed up to receive emails to some lists
immediately and daily/weekly digests for others.

### Diagram

![Sequence Diagram](adr-002/digests.png)

### Components

#### `DigestInitiatorService`

There are two classes to represent the respective digest periods:
`DailyDigestInitiatorService` and `WeeklyDigestInitiatorService`.

Their responsibility is to start the process to create digests and to ensure
that multiple digests are not started concurrently.

Initially this class was named `DigestSchedulerService` however we felt that
this was ill fitting with the classes actual responsibilities.

##### Shall

- Be interfaced by a scheduling service to run at a set time appropriate
  for their period
- Create a [`DigestRun`](#digestrun) model
- Ensure that multiple digests for the same period are not run concurrently
- Interface with `DigestRunSubscriberQuery` to determine which subscribers are
  due to receive emails for this digest

##### Should

- Be configurable as to what times a digest runs from and until

#### `DigestRun`

A model which represents a distinct run of a period of digest (daily or
weekly).

Has a responsibility to persist data that is related to a full digest run for
all subscribers.

We initially named this `Digest` however it transpired that there was already
a module in Ruby standard library named `Digest`.

##### Shall

- Store information such as:
  - Date digest is run on
  - The period the digest is for
  - The start time for the digest period
  - The end time for the digest period

##### Should

- Store a timestamp for when all the emails were created for the digest, to act
  as indicator that it is complete.

##### May

- Have a unique index for digest date and period, however this would limit
  ability to re-run a digest in the case of a problem.

#### `DigestRunSubscriberQuery`

Responsible for taking a [`DigestRun`](#digestrun) instance and using that to
determine which subscribers should receive an email for the digest period.

##### Shall

- Use a `DigestRun` to determine which subscribers should receive an email for
  a digest period
- Determine only the subscribers who will be due to be notified of at least one
  content change

##### Should

- Return a list of ids referencing `Subscribers`

##### May

- Return an ActiveRecord scope to allow the caller to deal with this returning
  an unlimited output

#### `DigestRunSubscriber`

A model which is used to associate a [`DigestRun`](#digestrun) with a
`Subscriber` instance. Will mostly be used as a persisted piece of data that
logs which subscribers receive an email due to a digest. It is unlikely to be
needed long term.

##### Shall

- Store
  - An association to `DigestRun`
  - An association to `Subscriber`

##### Should

- Store a timestamp for when it has been completed, can be used therefore to
  work out if a `DigestRun` is complete or not.

#### `DigestGenerationWorker`

A worker entity that accepts the argument of a
[`DigestRunSubscriber`](#digestrunsubscriber) and has the responsibility to
create an `Email` entity for the associated `Subscriber`.

##### Shall

- Pass the [`DigestRunSubscriber`](#digestrunsubscriber) to
  [`SubscriptionContentChangeQuery`](#subscriptioncontentchangequery)
  to retrieve a collection of `SubscriptionContentChangeQuery::Result`
  instances. Each of these represents a `Subscription` and `ContentChanges`
  associated with that subscription.
- Interface with [`DigestEmailBuilder`](#digestemailbuilder) to build an
  `Email` entity
- Create `SubscriptionContent` instances for each `ContentChange` per
  `Subscripption`

##### Should

- Mark a `DigestRunSubscriber` as completed
- Mark `DigestRun` as completed if all `DigestRunSubscriber` are complete for
  the `DigestRun`

#### `SubscriptionContentChangeQuery`

For a given [`DigestRunSubscriber`](#digestrunsubscriber) this will determine
all the `ContentChanges` associated with each `Subscription` for the digest
period.

This class began as an analogue of `SubscriptionMatcher` - which finds
`Subscriptions` associated with a `ContentChange` - we decided however that
this would require an additional class to interface with `DigestRunSubscriber`
and so decided to have this no longer be an inverse. We also decided that the
name should be suffixed with `Query` rather than `Matcher` and that we should
rename `SubscriptionMatcher` to have this suffix too.

##### Shall

- Return an array containing `SubscriptionContentChangeQuery::Result` instances
- The `SubscriptionContentChangeQuery::Result` instances will contain details
  of the `Subscription` and the `ContentChange` instances for that
  `Subscription`. This is to allow rendering the Email with `ContentChanges`
  in context with their `Subscription`.

##### May

- Only return necessary fields to limit memory usage/execution time

#### `DigestEmailBuilder`

A `DigestEmailBuilder` will take arguments of
[`DigestRunSubscriber`](#digestrunsubscriber) and a collection of
`SubscriptionContentChangeQuery::Result` objects. It will take this data and
use this to create an `Email` instance.

Formally this type of class was suffixed with Renderer eg `EmailRenderer`
however we felt that the class responsibilities should include persisting
an `Email` instance and therefore was a creation pattern.

##### Shall

- Create an `Email` instance
- Create an unsubscribe link

##### Should

- Be distinct from the email builder used to create immediate emails
- Be responsible for deciding what to do with duplicate `ContentChange` entries

### Supplementary changes

In order to implement these changes a number of existing areas were identified:

#### `Email` and `EmailRenderer` should be changed

We intend to rename the `EmailRenderer` class to reflect that it is for
immediate `ContentChanges`. This will be renamed `ImmediateEmailBuilder`.

We also intend to invert the responsibility of `Email` calling an instance of
`EmailRenderer` and instead of the instance of `ImmediateEmailBuilder` create
an instance of `Email`

#### Iterating `SubscriptionContent`

`SubscripionContent` is a model that was intended to associate `ContentChange`
entities with `Subscription` and `Email`. An absence of an email model was an
indication this required processing for an immediate email.

This however becomes problematic when we introduce `SubscriptionContent`
instances which are for digests and should not be processed as an immediate
email.

We decided the way to resolve this was to introduce an additional field to
`SubscriptionContent` which is a foreign key to `DigestRunSubscriber`. A null
entry for this column would indicate an email is intended for immediate
processing.


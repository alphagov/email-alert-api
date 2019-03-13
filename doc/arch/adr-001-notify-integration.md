# Decision Record: Initial architecture for Notify integration

## Introduction

In October 2017 we, the GOV.UK Email team, began a project where we are
intending to expand the responsibilities of email-alert-api application to
handle creating and sending of alerts that enter the system. The changed system
intends to use [Notify][notify] as the transportation layer to send emails.

As part of considering this we have conducted a piece of work to outline the
architecture for the application which this document presents.

### How we are treating digests

At the time of putting this together it was unclear exactly what the product
decisions and functionality would be regarding digests, however we did want
them to be considered in the architecture. For clarity this explains our best
guess understanding of how digests will work prior to appropriate product
decisions.

- Digests are expected to continue current behaviour of merging multiple
  subscriptions into a single email.
- It is not essential that digests return the same content for each user with
  same subscriptions. E.g. a digest processed for Joe processed 2 mins after
  Steve may get slightly different results if something was published in that
  time.
- If you are subscribed to things that produce the same content for two
  subscriptions at different digest frequencies, you will only receive
  notifications for a piece of content once (on the higher frequency).
- Digests take effect from the point of subscription. E.g. if you joined a
  weekly digest on a Wednesday that was sent on Fridays you’d only get alerts
  for content after you joined We can send remaining digest emails out when
  someone changes subscription preferences.

[notify]: https://www.notifications.service.gov.uk/

## Specifics

The architecture can be visualised through two diagrams:

1. [Domain model](../domain.png) which represents the data models and how they
   relate
2. [Sequence diagram](../sequence_diagram.png) which represents all of the
   components and how they communicate to achieve specified functionality

This document then goes through each of the concepts in the diagram and
outlines their roles and responsibilities.

### ContentChange

**Responsibility**: Representing a piece of content that is either new or has
changed and should produce an alert.

#### Shall

- Store information such as:
  - Title of content
  - Description of content
  - Change note (if any) associated with the update
  - Path to content

#### Should

- Store information about what subscription criteria it matches (links, tags,
  supertypes)
- Have fields required for auditing
  - Where the request came from
  - Be able to determine whether and when it has been processed by a worker
    (processed_at presence)
- Be persisted forever

#### May

- In future, have an association to an entity that models the subscription
  criteria information (links, tags, super types)
- Be considered as part of an Alert supertype which may represent other types
  of alerts in the system

### Subscriber List

**Responsibility**: Being a type of list that a user can subscribe to and storing
information specific to that list.

#### Shall

- Store information such as
  - List name

#### Should

- Require that the list name is unique, as we don't know how to differentiate
  identically named lists to users yet
- Temporarily maintain a relationship with corresponding govdelivery list
- Store information about what subscription criteria it matches
  (links, tags, document_supertypes)
- Have information to source where the Subscriber List originated from

#### May

- In future, have an association to an entity that models the subscription
  criteria information (links, tags, super types)
- Release the requirement of a list name being unique if we are able to
  establish a way to differentiate between lists
- Store statistics related to the list
- Be stored even after it is removed - for logging purposes, dependent on if
  this will impact unique constraints

#### To determine

- In what scenarios is a Subscriber List removed

### Subscriber

**Responsibility**: Represent an individual user that can subscribe to content,
stores information related to all subscriptions the user may have

#### Shall

- Store information such as
  - Email Address
- Support an email address changing

#### Should

- Be deleteable, a user may wish to remove their account - this should not
  break history of emails sent
- Be used in the future for authentication purposes

#### May

- Store preferences that affect all of a users subscriptions
- Have the ability to be disabled if there are problems with a users account
- Store other personalisation information such as name
- Be associated with statistics regarding the subscriber

#### To determine
- What should we allow in terms of removing a subscriber - do we use the
  associated data as a log?

### Subscription

**Responsibility**: Store that a Subscriber has an association to a Subscriber
List and any associated data (e.g. preferences)

#### Shall

- Store an association to a Subscriber
- Store an association to a Subscriber List

#### Should

- Be used to store preferences associated with a particular subscription

#### Should Not

- Be removed from the system when a user unsubscribes from a Subscriber List as
  this provides a log that a user has been subscribed with the associated
  content and maintaining the record allows us to restore preferences if
  subscription is resumed

#### May

- Be used to store statistics on a subscribers activity relating to that
  subscription
- In future be something that can be paused

#### To determine

- What should happen if either Subscriber List or Subscriber are removed/archived

### SubscriptionContent

**Responsibility**: Represent that a content change should or has been emailed to a
subscription

#### Shall

- Have an association with a ContentChange
- Have an association with a Subscription
- Have a nullable association with Email
- Know whether it has been processed

#### Should

- Allow for multiple subscriptions associated with the same Subscriber to be
  associated with the same ContentChange - It is the EmailGeneration
  responsibility to consolidate these
- Allow for multiple entries with same ContentChange and Subscription - to
  allow a content change to be reprocessed in the event of an error
- Support Email records being removed from the system for auditing process
- Be deleteable for a scenario that a user changes a subscription before an
  email is sent

#### To determine

- What is the archiving strategy on these? Will they be persisted forever or
  match persistence strategy of Emails for instance?

### Email

**Responsibility**: A distinct email that the system will be sending or has sent

#### Shall

- Be created any time Email Alert API sends an email
- Store information such as
  - Recipient
  - Subject
  - Body (in Notify Markdown)
- Delivery status

#### Shall Not

- Have more than one recipient
- Know anything about the content that led to its generation

#### Should

- Only exist in the database for a non permanent time period
- Be associated with a Subscriber for logging purposes

#### May

- Be archived into a log somewhere for later analysis

### DeliveryAttempt

**Responsibility**: Storing the information used to communicate with the
transportation service for email

#### Shall

- Store information such as
  - Email associated with
  - Provider (e.g. Notify)
  - Provider Reference (An id to look up the email)
  - Status (success/pending/failure)
- Any provider specific errors/warnings

#### Should

- Be created whenever an email is attempted to be sent
- Be updated when sufficient information is known about whether an email has
  sent or not
- Be deleted when an Email is deleted

#### May

- Be created in a success state if it was known the delivery attempt was
  successful synchronously
- Be used in future with different transport mechanisms if we expand beyond
  Email

### ContentChangeController

**Responsibility**: Storing a ContentChange, enquing that for processing,
returning a success

#### Shall

- Create a ContentChange model
- Enqueue a SubscriptionContentWorker job

#### To determine

- Who has responsibility for the Worker failing to run?

### SubscriptionContentWorker

**Responsibility**: Responsible for determining which subscriptions should receive
an email prospectively and creating SubscriptionContent objects accordingly

#### Shall

- Be given sufficient input to lookup a ContentChange
- Liaise with SubscriptionMatcher to determine all subscriptions that match a
  ContentChange
- Create SubscriptionContent entities for all subscriptions that match a
  ContentChange
- Trigger EmailGenerationWorker for emails that have to run immediately

#### Should not

- Be able to have multiple instances of this worker processing the same
  ContentChange concurrently

#### May

- Accept frequency as an argument to match subscriptions for that frequency in
  order to allow rebuilding of emails that went out in error

### SubscriptionMatcher

**Responsibility**: When given a certain criteria determine which Subscription
objects are associated with it

#### Shall

- Accept ContentChange object as input
- From input determine which Subscription objects match
- Will use existing logic in SubscriberListQuery

#### To determine

- Should we be considering how this might scale for a huge number of
  subscriptions?

### EmailGenerationWorker

**Responsibility**: Responsible for finding Subscription objects that should be
sent at a given frequency and producing Email objects that can be sent

#### Shall

- Find SubscriptionContent entities that match that frequency and have not been
  processed
- Take one or more SubscriptionContent entries for a user and create a
  corresponding Email entity
- Update SubscriptionContent entries to associate them with an email and
  indicate they are processed
- Liaise with EmailRenderer to convert one or more SubscriptionContent entities
  into the subject and body for an Email

#### Should

- Take input of a frequency (immediate, weekly, daily)
- Be able to consolidate SubscriptionContent entries that refer to the same
  ContentChange

#### Should not

- Be able to process the same SubscriptionContent objects in multiple
  concurrent processes

#### May

- Have its interface reconsidered to allow for increased ability to build
  emails in parallel

#### To determine
- If a user has multiple subscriptions which are at different frequencies, is
  this the class that will consolidate them?

### DigestTimer

**Responsibility**: Triggering EmailBuilderWorker to run at a given frequency

#### Shall

- Trigger EmailGenerationWorker to run at daily intervals
- Trigger EmailGenerationWorker to run at weekly intervals

#### To determine

- When these intervals are
- What mechanisms would be in place to handle this failing to occur

### EmailRenderer

**Responsibility**: Converting one or more Email Entries into a Notify Markdown
formatted text

#### Shall

- Take input of one or more SubscriptionContent entities and a frequency
- Generate a subject in plain text
- Generate a body in Notify Markdown

#### Should

- Be able to generate differently formatted emails for weekly and daily emails

#### May

- Have sufficient information to include unsubscribe links in emails

### EmailDeliveryWorker

**Responsibility**: Finding Emails that should be sent and creating
DeliveryAttempts for them and updating Email status accordingly

#### Shall

- Communicate with a transportation layer (Notify) to send an Email
- Create a DeliveryAttempt object to associate with the Email
- Update the Email and DeliveryAttempt objects based on the outcome of the
  request

#### Should

- Be able to retry requests to Notify that fail and are retryable (e.g.
  temporary network outage)
- Be able to abort trying to send an email if it’s a situation where retrying
  won't result in a success (e.g. 400 bad request)

#### May

- React to the transportation layer returning a 429 status code

#### To determine

- What should happen when an email has exhausted retries
- What should happen when an email fails due to a bad request

### DeliveryMonitor

**Responsibility**: Determining whether Notify was able to send emails we have
tried to send or not

#### Shall

- Communicate with a transportation layer (Notify) to determine if a pending
  delivery attempt is still in progress, successful or a failure
- Update the Email and DeliveryAttempt objects based on the outcome of the
  request

#### Should

- Be able to abort attempting to send an email if Notify returns a temporary
  failure for that email address
- Be able to remove/suspend a users account if Notify returns a permanent
  failure for the corresponding email address
- Be able to retry sending an email if Notify returns a notify failure error
  which indicates a sending can be retried

#### To determine

- Which system (if any) and what rules and behaviour it will follow for
  removing/suspending accounts that receive permanent failure messages from
  Notify

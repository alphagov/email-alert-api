# Decision Record: Message Concept

## Introduction

In September 2019 a new concept was added to Email Alert API: Message. It is
a new type of notification that can be triggered by Email Alert API and, like
content changes, can be sent as an immediate email or part of daily/weekly
digests.

It is intended to provide a means for applications to alert subscribers to
ad hoc events that may not be represented by a content change.

## Specifics

### Context

The need for a new type of notification was identified to support the [GOV.UK
Get ready for Brexit checker](https://www.gov.uk/get-ready-brexit-check). This
service returns people a list of tailored results based on answers users
give about their circumstances. Users can then sign up for email notifications
when these results change or new ones are added.

The presence or change to a result is not captured in an event sent to the
Publishing API. This is because these results are managed by code and a result
may or may not represent a page on GOV.UK, the logic to see a result is also
complex. It was therefore established that there should be a means to send
notifications via a direct call to Email Alert API outside of the
existing approach that is triggered automatically based on Publishing API
events.

### Existing approaches

In recent times there have been two previous scenarios where we have used
Email Alert API to send subscribers emails outside of the content change
notification mechanism.

The first of these was [Unsubscribe notifications][unsubscribe-pr] for when a
policy, policy area or taxon was unpublished. These used a custom endpoint
on Email Alert API specifically for this task. This resolved the problem of
informing users of this change but had the negative effect that the code
introduced couldn't be re-used for similar scenarios and raises questions
about whether this is a feature that is needed permanently.

The second was [Notify subscribers of Business Readiness tagging][br-pr] where
Content Tagger sends Email Alert API a synthetic content change to generate
notifications for an event that normally would not produce a notification.
This had the disadvantage that it involved semantically incorrect data being
used to populate a content change which means compromising data consistency.

[unsubscribe-pr]: https://github.com/alphagov/email-alert-api/pull/655
[br-pr]: https://github.com/alphagov/content-tagger/pull/900

### Decision

To meet the needs of the Get ready for Brexit checker we decided a new concept
was needed in Email Alert API to support the ability to send notifications to
subscribers using an approach distinct from content changes. This introduces
a new entity to Email Alert API called message. A message is similar to a
content change but instead has less structure in the data, which allows their
information and appearance to be customised by the API client.

In adding messages to Email Alert API two principles were followed. The first
is to avoid any Get ready for Brexit domain logic directly to Email Alert API,
this is to maximise the reusability of the functionality. The second principle
is to not build more functionality than is needed for the current needs, this
is to not over commit this functionality into resolving hypothetical needs
at this point in time.

These principles intend to provide messages with a foundation that can be used
to build on this functionality to meet future needs while retaining a low cost
of modification/deletion were we to decide there are different or no future
needs.

To provide flexibility with a messages content we allow API clients to insert
markdown that can be parsed by Notify. There is no validation of this syntax,
therefore it is the responsibility of a client app to provide markdown that is
within the [limited subset][notify-markdown] that Notify supports.

Messages are included in digests in the same manner to content changes. If a
list was to have messages and content changes these would be grouped together
and ordered by the time they were added to Email Alert API.

[notify-markdown]: https://github.com/alphagov/notifications-utils/blob/f73fbda03467e558f53224f2b5f901e12d19c858/notifications_utils/formatters.py#L356

#### Matching to subscriber lists

A peculiarity introduced by the Get ready for Brexit lists is that each
notification has potentially complicated logic as to which audiences should
see it. This is an inversion of the responsibilities of content change
notifications where typically a subscriber list has rules and content changes
contain data, in this scenario subscriber lists are treated as storing data
and the message itself contains the rules.

To cater for the complicated logic another concept was introduced to Email
Alert API, this is [criteria rules][cr-pr]. It provides a [JSONSchema][]
inspired approach to specify a recursive structure
of rules where `any_of` or `all_of` predicates are met. This allows
associating with particular links and/or tags. Example:

```json
[
  {
    "any_of": [
      { "type": "tag", "key": "brexit_checklist_criteria", "value": "nationality-eu" },
      { "type": "tag", "key": "brexit_checklist_criteria", "value": "nationality-row" }
    ]
  },
  {
    "any_of": [
      { "type": "tag", "key": "brexit_checklist_criteria", "value": "living-eu" },
      { "type": "tag", "key": "brexit_checklist_criteria", "value": "living-row" }
    ]
  },
  { "type": "tag", "key": "brexit_checklist_criteria", "value": "join-family-uk-yes" }
]
```

This logic is then used at the point of determining which subscriber lists
match a particular message.

[cr-pr]: https://github.com/alphagov/email-alert-api/pull/959
[JSONSchema]: https://json-schema.org/
[any-json-schema]: https://json-schema.org/understanding-json-schema/reference/combining.html#anyof
[all-json-schema]: https://json-schema.org/understanding-json-schema/reference/combining.html#allof

### Future avenues

There message functionality has future options to expand to meet potential
needs. On the modest side this could be used as a semantically accurate way
to notify subscribers when content is tagged to a list, or to notify people
of changes to their lists. Whereas on the more adventurous side it could be
used as a means to provide mailing lists for different types of content.

The introduction of criteria rules offers an alternative approach that can be
used to define what rules a subscriber list applies to. This could be used to
replace the `links`, `tags`, `document_type`, `email_document_supertype` and
`government_document_supertype` fields with a single one. This would allow for
a consolidation of logic and opportunities for more specific subscriptions.

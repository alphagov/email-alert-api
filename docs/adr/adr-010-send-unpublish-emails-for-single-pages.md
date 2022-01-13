# Decision record: reinstate unpublish emails for single page subscriptions

Date: 2021-12-03

## Context

We have just launched a new email notifications feature that allows users to subscribe to updates on a single page.
Currently this feature is only enabled on a few selected pages (eg. [Open standards for government][open-standards-for-government]),
but it is expected to roll out to the majority of pages and content types by early 2022.

Unpublished content will become unavailable and receive no further updates. Users who have demonstrated a desire to stay up to date
with an item of content may find it unexpected if content they were subscribed to disappears without notification, or becomes unavailable through their account. This change is part of meeting a user need to stay up to date with changing content, including when that content is changed through unpublication.

The email alert API used to send emails when a page in a taxon subscription was unpublished.
This feature was [removed in Jan 2021][remove-previous-unpublish-emails] for good reasons.

[open-standards-for-government]: https://www.gov.uk/government/publications/open-standards-for-government
[remove-previous-unpublish-emails]: https://github.com/alphagov/email-alert-api/issues/1572

## Decision

We will add an endpoint to email-alert-api to unsubscribe everyone from a given subscriber list, and optionally send them an email with a reason why (using the existing [message](https://github.com/alphagov/email-alert-api/blob/main/docs/adr/adr-004-message-concept.md) machinery).  We will change email-alert-service to call this new endpoint when a page gets unpublished, to notify any users subscribed to that specific page.

We will not delete the now-empty list, as it will be cleaned up by the [HistoricalDataDeletionWorker](https://github.com/alphagov/email-alert-api/blob/main/app/workers/historical_data_deletion_worker.rb), and introducing another mechanism that destroys lists could be a point of confusion.

### Addressing the concerns from the previous version

The previous version of this feature was removed for several good reasons. We believe readding the unpublish emails only for single page subscriptions addresses these concerns:

#### It only worked for topic taxons

Single page notification work generates a clearer user need to inform about subscriptions in the more frequent scenario that individual pages are unpublished.

Given the specificity of the need that drives this, we don't think limiting it to just those subscriptions is a problem.

#### It only worked if the unpublished page was redirected

The new unpublished emails will handle pages that are redirected or published in error with or without an alternative URL. This covers the publisher-facing [unpublishing types][unpublishing-types].

#### It wasn't monitored so we didn't know if it was working

We don't have a specific plan for monitoring this. Ideally monitoring for this would be taken on by a team that owns this portion of the system in the log run, and incorporated into their usual service monitoring.

#### It rendered email using ERB, unlike the rest of the system

The new unpublished emails will use the same method to render emails as the messages endpoint.

#### It removed any subscriber lists that included the page, even those for a different taxon

We are taking a very different approach from the previous unpubication of taxons. The previous route had to infer which lists should be removed as they represented a collection of materials.

Here we are unpublishing a single page, and matching it to a subscription list by the same content ID. The email alert api doesn't need to do anything clever to match the two, we just tell it which subscription list should be cleared, and it does so.

#### There was no evidence it met user needs

We have user research demonstrating a need for users to stay up to date with specific items of government guidance. Examples might be recent coronavirus guidance that changes over time and can have a large impact on lives and what is possible to do.

Unpublication is a form of change to that content that is currently unmonitored. This could have an impact in scenarios such as when a specific item of guidance is consolodated into a more general page when rules are made the same. A user may also be confused if an item they have subscribed to disappears from their account without notification, and may also wish to know if an item they subscribed to was removed as published in error.

We have focused in on these as derived needs that emerge from the general user need to be kept up to date with individual pages.

### Other related issues

The email alert API has subscriber lists that will never send an email. This is documented as [GOV.UK Tech Debt][email-alert-api-dead-lists].
This proposal does not directly address this Tech Debt, but by removing subscriptions from the subscriber list once the emails have been sent the [HistoricalDataDeletionWorker](https://github.com/alphagov/email-alert-api/blob/main/app/workers/historical_data_deletion_worker.rb) can periodically remove the empty lists.

[unpublishing-types]: https://github.com/alphagov/publishing-api/blob/a33292a3002d722a5b5840aaea751ebe10304c28/app/commands/v2/unpublish.rb#L37
[email-alert-api-dead-lists]: https://trello.com/c/PjRE1A0G/200-email-alert-api-has-dead-lists-that-will-never-send-any-email

## Status

Proposed

## Consequences

- Increased complexity in email-alert-service with new MessageProcessors monitoring for unpublication events
- A new email-api endpoint to mass unsubscribe users from a subscription list.

Subscription lists may end up unpopulated and empty as a result of this, the proposed endpoint does not clear them up themselves (so is not a strict destroy endpoint), instead it relies on other existing workers which periodically clear up empty subscription lists.

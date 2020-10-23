# 6. Email Delivery Responsibilities

Date: 2020-10-23

## Context

Email, as an asynchronous communication medium, inherently has two boolean
scenarios that need to be true for an email to be received. An email has to be
_sent_ to a mail server and the mail server then needs to _deliver_ the email to the
recipient's mail server. Resolving whether an email is sent is a rather simple
question that can be resolved synchronously - "did the mail server accept the
email?" - however, determining whether an email is received is more complex
as delivery is not synchronous and may be subject to automated retrying should
any problems occur. Typically, in the medium of email, clients only consider
the first scenario in reporting an email's status, this is the point an email
becomes sent. The latter scenario, delivery, isn't typically reflected in
email clients, it is normal to assume the email was received
successfully unless later you receive an email indicating a bounce has
occurred.

The [initial Email Alert API Notify integration][adr-1] was designed to
consider both the sending and delivery of email. It had systems to monitor
whether Notify had managed to deliver an email to a recipient and an automatic
retry mechanism for when Notify had problems delivering an email.

In September 2020 we decided to re-evaluate this concept conflation as we were
concerned that Notify functionality was duplicated in Email Alert API and
that this had an adverse effect on the complexity of the system.

[adr-1]: adr-001-notify-integration.md

## Decision

We decided that Email Alert API has a responsibility to send email, but does
not have a responsibility to deliver it. That is the responsibility of Notify.

We defined that, in the context of Email Alert API, the process of sending
email was the ability to successfully send a request to Notify to perform
this action - we consider this the equivalent of a mail client successfully
sending an email to an [SMTP][] server. We then consider the
[Notify callback][notify-callback] as the mechanism to learn if an email was
delivered or not.

To reflect this we have [switched][switched-to-sent-success] the
meaning of an [email's status][email-status]. A status of "sent" now means that
the email was accepted by Notify and not that the email was delivered. A
status of "failed" now means we weren't able to send the email to Notify,
instead of the previous meaning where it meant that it may not have been sent
to Notify or Notify failed to deliver the email.

[SMTP]: https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol
[notify-callback]: https://docs.notifications.service.gov.uk/ruby.html#delivery-receipts
[switched-to-sent-success]: https://github.com/alphagov/email-alert-api/commit/c457f62c3b6f1eaadf47e6596223cc0fdcffa853
[email-status]: https://github.com/alphagov/email-alert-api/blob/0b87e62288ddb1653451f84e1f36e17ce4e8e9dc/app/models/email.rb#L7

## Status

Accepted

## Consequences

### We no longer retry delivering emails ourselves

Notify, via Amazon SES, will automatically [retry][ses-bounce] the delivery of
emails that fail for transitory reasons (such as the recipient's mail server
being full or offline). If it doesn't succeed in a reasonable period
of time Notify will inform us by telling us an email has experienced a
["temporary-failure"][temporary-failure-status].

Email Alert API [no longer][no-retries-commit] has its own retry
mechanism to re-attempt emails that have failed to be delivered. This
resolves an aspect of duplicated functionality between the two systems and
an area of ambiguity as to how long Email Alert API should retry for. With
this removed there are no longer attempts to resend an email should the
first delivery fail, this allowed us to [delete the
`DeliveryAttempt` model][delete-delivery-attempt] as the purpose of this was
to disambiguate between different Notify requests.

[ses-bounce]: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-concepts-deliverability.html#send-email-concepts-deliverability-bounce
[temporary-failure-status]: https://docs.notifications.service.gov.uk/ruby.html#status-email
[no-retries-commit]: https://github.com/alphagov/email-alert-api/commit/df9ad09fab5dabde5fac92ae76d155d00eea192b
[delete-delivery-attempt]: https://github.com/alphagov/email-alert-api/pull/1438

### We no longer record delivery data with an email

A question we pondered with these changes was "what should do with the data
we receive from Notify about the delivery of emails?". This data no longer plays
a role in the state modelling of email sending, so we decided it should not
be represented in an email's status. (it conflated what a failure to send
an email meant - was this failure to _send_ or failure to _deliver_?).

We decided that we did not need to store delivery success or failure in the
database with the email. This is because there is not currently
a known use of this data and, since the email table only has a 7-day retention
period, it can be added later to meet any later needs that are identified. The
data remains available via the Notify UI for debugging whether emails
were delivered.

We [continue to act on "permanent-failure"][permanent-failure]
notifications and remove subscriptions for non-operational email addresses -
this can be done without storing additional data with the email. We also
continue to store aggregate metrics about email sending which power dashboards.

[permanent-failure]: https://github.com/alphagov/email-alert-api/blob/59fc71a58317ef2998f2c0ef102020da3ca9df96/app/services/status_update_service.rb#L17-L19

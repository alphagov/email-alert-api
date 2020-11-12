# 7. Monitoring and alerting

Date: 2020-11-13

## Context

Email Alert API has acquired the undesirable reputation of an application that
produces a high volume of unactionable alerts and is a frequent source of
GOV.UK incidents. The monitoring and alerting approach no longer appears to
be sufficient for the application behaviour as the volume of work for the
application has changed in the past 2 years. In previous years, the application
would reach a peak of sending 1 million emails a day whereas now it can be
sending over 10 million emails a day. This increased volume of work has
increased system latency which has impacting alerts and contributed to
incidents.

The approach used to monitoring the application and the wider email alert
system is two fold. One approach is to monitor Email Alert API's internal
state to see if it is [completing tasks within a particular
time frame][monitor-time-frame] or [whether there is a high quantity of work to
do][monitor-workload]. The other approach is to use an [end-to-end
test][email-alert-monitoring] which checks a Gmail account to identify that
a particular address received an expected email within a time frame. Both of
these approaches are flawed.

Monitoring for high quantities of work, and whether work was completed, in a
time frame has left Email Alert API vulnerable to producing alerts when the
application is busy, yet fully operational. These alerts are unactionable for
support engineers as the alerts resolve themselves once the work is completed
and there is little to nothing an engineer can do to speed this process up.
For example, if the application has accumulated 1,000,000 emails to send it
raises a critical alert even if it is sending these at the fastest rate Notify
would allow. These alerts, therefore, waste the time of support engineers and
create a risk that a support engineer might miss an alert that requires their
intervention.

Since these alerts can't be relied upon to suggest the application is
broken, they aren't used for any out-of-hours alerts. This means that if they
did reflect a genuine problem no engineers would be contacted. An engineer
instead learns of a problem out-of-hours due to the other type of monitoring
approach: the end-to-end test. These alert when content published
through [Travel Advice Publisher][] does not arrive in a Gmail inbox within a
specified time period.

Monitoring an inbox provided its own distinct flaws. If Email Alert API is
broken out-of-hours engineers would not be notified unless travel advice
content was published. This alert also monitor beyond the boundaries of
the email alert system - considering whether GOV.UK publishing, Notify and
Gmail are all working - leading to alerts representing problems outside the
control of GOV.UK engineers. Finally, by nature of being time based, these
alerts are also vulnerable to the system being busy - where a sufficiently
high volume of travel advice publishings guarantees that an alert will
trigger.

Reviewing these helped us understand the reputation for unactionable alerts and
reviewing the GOV.UK incidents for Email Alert API helped us to identify
patterns where incidents reflected ambiguity over whether the system
was broken or not. We felt there was room for improvement.

[monitor-time-frame]: https://github.com/alphagov/email-alert-api/blob/c70fcd7e5d64393074a3eebd83b3467fd8cc03b3/app/workers/digest_run_worker.rb#L6-L9
[monitor-workload]: https://github.com/alphagov/govuk-puppet/blob/fac4b5163f10736bb19aa51a8eb7bc276dd2cb40/modules/govuk/manifests/apps/email_alert_api/sidekiq_queue_check.pp#L33-L44
[email-alert-monitoring]: https://github.com/alphagov/email-alert-monitoring
[Travel Advice Publisher]: https://github.com/alphagov/travel-advice-publisher

## Decision

Our decision is that the system should raise a critical alert
[if and only if](https://en.wikipedia.org/wiki/If_and_only_if) the email alert
system is broken. The majority of these alerts should contact engineers
out-of-hours.

Unpacking this, we consider the email alert system to be comprised of 3
applications: Email Alert API,
[Email Alert Frontend](https://github.com/alphagov/email-alert-frontend) and
[Email Alert Service](https://github.com/alphagov/email-alert-service); this
excludes the monitoring of whether GOV.UK publishing is working and whether
Notify is working as they are independently monitored. The use of
"if and only if" reflects a condition we're forming that the system will not
raise critical alerts unless we're highly confident it is broken, whereas
warnings are appropriate for other situations. We decided that for the email
alert system to be "broken" it represents a failing that will lead to a user
noticeable issue unless an engineer intervenes. Since these alerts should
represent a broken system requiring intervention, it should be suitable to
contact engineers out-of-hours for them as otherwise users will be
experiencing issues.

We decided that we will re-approach our alerting with this mindset and look to
replace alerts that are vulnerable to reflecting a busy status.

## Status

Pending

## Consequences

We will be changing the approaching to monitoring and alerting across the email
alert system of applications in order to meet this new alerting criteria.

## Monitoring Email Alert API

### Sidekiq workers

We will configure critical alerts, that contact engineers out-of-hours, if
individual Sidekiq jobs fail multiple times for the following workers:

- [DailyDigestInitiatorWorker][]
- [DigestEmailGenerationWorker][]
- [ProcessContentChangeWorker][]
- [ProcessMessageWorker][]
- [SendEmailWorker][]
- [WeeklyDigestInitiatorWorker][]

These workers will use the database to store the amount of times we have
attempted to perform an action. An alert will be raised if the quantity of
failed attempts reaches a threshold (the suggestion is 5).

We will contact engineers out-of-hours if either [SendEmailWorker][] or
[DigestEmailGenerationWorker][] have not completed at least one successful run
within a time period (suggestion is 30 minutes) despite work existing. This
reflects a concern that we would like support engineers to be notified quickly
if all instances of these jobs are failing and the aforementioned retry method
may take a long time to alert in a busy period.

Similarly, we will contact engineers out-of-hours if we determine that
[DigestRuns][DigestRun] are not created within a reasonable time frame
(suggestion is 2 hours). Creating these is a [trivial][digest-run-creation],
but essential, operation for producing a digest and the lack of these suggests
the system is broken whether it is busy or not.

We will also monitor that runs of [RecoverLostJobsWorker][] and
[MetricsCollectionWorker][] are succeeding at least once within a time frame
(suggestion is 1 hour). These jobs should continue running even when the
system is busy and the lack of them running indicates that we no longer have
confidence the system is monitored or able to recover. Thus, an alert will be
created that contacts engineers out-of-hours should these never succeed in a
time frame.

For Sidekiq workers that don't affect the user noticeable aspects of Email
Alert API, such as [EmailDeletionWorker][], we won't raise critical alerts if
these are failing. Instead we will raise a warning if any Sidekiq workers
exhaust all their retries and are placed in the [dead set][sidekiq-dead]. This
approach was chosen as it was a pragmatic technique to monitor multiple workers
without adding checks for individual workers.

We will modify the [latency checks for email queues][latency-checks] to be
significantly less sensitive to latency for all email sending except
[transactional emails][]. This is because transactional emails have an
[expectation of a prompt delivery][transactional-delivery-expectation] and the
lack of them blocks a user from progressing with their task. For the other
queues we will change the time before a warning occurs to be in the measure of
multiple hours compared to minutes, with the intention that they serve to
alert a support engineer only when the system is exceptionally busy and may be
unhealthy. These alerts will only reach a critical status if they hit a 24 hour
point as this would indicate that we are consistently creating email faster
than the application can send it, which may mean the system is perpetually
backlogged.

### Web application

We decided that there should be a mechanism that alerts people out-of-hours if
the Email Alert API web application appears broken, noting that currently an
engineer is unlikely to be contacted in the event of the whole Email Alert API
application becoming unavailable - unless travel advice were published. We
noted there wasn't a particularly consistent approach to this across GOV.UK
([with some apps raising an out-of-hours alert when a single instance fails
healthchecks][publishing-api-alert]) and felt it would be good to take a simple
approach to avoid surprising engineers.

We decided the most appropriate place to alert would be when [the application
load balancer has no healthy instances of the application][aws-lb-check]. This
represents that no instances of the web application are healthy and
[no requests will succeed][aws-alb-health].

### Alerts to be removed

We will remove the following alerts that will become superseded:

- [Content Changes unprocessed after 2 hours][unprocessed-content-changes]
- [Messages unprocessed after 2 hours][unprocessed-messages]
- [Incomplete DigestRuns after 2 hours][incomplete-digest-runs]

## Monitoring Email Alert Service

Email Alert Service listens for [Publishing API][] events and communicates
these to Email Alert API. We currently [only have alerts][rabbitmq-alert] that
occur in-hours if this system fails, so there is no visibility for any
out-of-hours problems.

We intend to improve this by raising an alert that contacts engineers
out-of-hours if there is a pattern of failure in processing these events.

## Monitoring Email Alert Frontend

Email Alert Frontend acts as the public interface for subscriber interaction
with the email alert system. This web application will be monitored in a
[similar way to the Email Alert API web application][#web-application] by
considering whether the load balancer has any healthy instances.

## Removal of Email Alert Monitoring

[Email Alert Monitoring][email-alert-monitoring] is the aforementioned
end-to-end test that monitors whether travel advice and drug advice content
changes send email to a Gmail inbox. The changes to alerting described in this
ADR will render Email Alert Monitoring redundant, as the new alerts should
capture real problems faster and cover a broader range of scenarios - this
would leave Email Alert Monitoring capturing false positives and out-of-scope
problems.

Once the new monitoring and alerting approaches have been implemented and
tested we will remove Email Alert Monitoring from the GOV.UK stack.

[DailyDigestInitiatorWorker]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/workers/daily_digest_initiator_worker.rb
[DigestEmailGenerationWorker]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/workers/digest_email_generation_worker.rb
[ProcessContentChangeWorker]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/workers/process_content_change_worker.rb
[ProcessMessageWorker]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/workers/process_message_worker.rb
[SendEmailWorker]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/workers/send_email_worker.rb
[WeeklyDigestInitiatorWorker]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/workers/weekly_digest_initiator_worker.rb
[DigestRun]: https://github.com/alphagov/email-alert-api/blame/b92f9136230f9217e7877c6dbd6a049473ce7b35/README.md#L28-L29
[digest-run-creation]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/services/digest_initiator_service.rb#L8
[RecoverLostJobsWorker]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/workers/recover_lost_jobs_worker.rb
[MetricsCollectionWorker]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/workers/metrics_collection_worker.rb
[EmailDeletionWorker]: https://github.com/alphagov/email-alert-api/blob/b92f9136230f9217e7877c6dbd6a049473ce7b35/app/workers/email_deletion_worker.rb
[sidekiq-dead]: https://github.com/mperham/sidekiq/wiki/API#dead
[latency-checks]: https://github.com/alphagov/govuk-puppet/blob/3922b4104e61e16e115e609a1f96fa19bffcfb0c/modules/govuk/manifests/apps/email_alert_api/checks.pp#L9-L25
[transactional emails]: https://github.com/alphagov/email-alert-api/blob/fe28935ae77137182ec713059b029d514a93bc2d/config/sidekiq.yml#L9
[transactional-delivery-expectation]: https://github.com/alphagov/email-alert-frontend/blob/de1caeea8098eccbb34d8768d7f2c95e455d901c/config/locales/subscriber_authentication.yml#L21
[publishing-api-alert]: https://github.com/alphagov/govuk-puppet/blob/3922b4104e61e16e115e609a1f96fa19bffcfb0c/modules/govuk/manifests/apps/publishing_api.pp#L168-L170
[aws-lb-check]: https://github.com/alphagov/govuk-puppet/blob/3922b4104e61e16e115e609a1f96fa19bffcfb0c/modules/monitoring/manifests/checks/lb.pp
[aws-alb-health]: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html#introduction
[unprocessed-content-changes]: https://github.com/alphagov/govuk-puppet/blob/3922b4104e61e16e115e609a1f96fa19bffcfb0c/modules/govuk/manifests/apps/email_alert_api/checks.pp#L27-L36
[unprocessed-messages]: https://github.com/alphagov/govuk-puppet/blob/3922b4104e61e16e115e609a1f96fa19bffcfb0c/modules/govuk/manifests/apps/email_alert_api/checks.pp#L49-L59
[incomplete-digest-runs]: https://github.com/alphagov/govuk-puppet/blob/3922b4104e61e16e115e609a1f96fa19bffcfb0c/modules/govuk/manifests/apps/email_alert_api/checks.pp#L38-L47
[Publishing API]: https://github.com/alphagov/publishing-api
[rabbitmq-alert]: https://github.com/alphagov/govuk-puppet/blob/3922b4104e61e16e115e609a1f96fa19bffcfb0c/modules/govuk/manifests/apps/email_alert_service/rabbitmq.pp#L54-L60

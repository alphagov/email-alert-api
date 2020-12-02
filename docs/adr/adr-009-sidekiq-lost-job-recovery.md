# 9. Sidekiq Lost Job Recovery

Date: 2020-12-02

## Context

We use [Sidekiq](https://github.com/mperham/sidekiq) to do background processing in Email Alert API. This includes critical tasks, such as generating and sending email. However, it's possible for these jobs to be lost:

1. If the code to enqueue the job in Redis fails, either for transient reasons, or due to a bug.

2. If a worker process quits ungracefully, while processing a job.

The second issue has occurred frequently due to workers being [forcibly restarted][icinga-memory] when they consume too much memory. A memorable example was the loss of a Travel Advice content change, which was detected by the [alert][travel-advice-alert] for travel advice emails, and lead to an incident. Conversely, we don't think the first issue does not occur frequently.

It's an effortful task to recover lost jobs, due to the complexity of how we generate and send email in the system. The job will no longer exist in Redis, but a record of it will exist in the database, with a flag to indicate its completion. For example, we can check the [`status` field][email-status] of an Email to see if the [job][send-email-worker] to send it has completed. By analysing these and similar flags and timestamps in other tables, we can work out which work has not been completed in good time.

Ideally these issues wouldn't exist in the first place. Previously we considered upgrading to Sidekiq Pro, which [persists][sidekiq-reliability] jobs in Redis while they are being processed. Using Sidekiq Pro would therefore prevent the second issue, but not the first, which is unrelated to Sidekiq. It's also worth noting that we previously had [concerns][sidekiq-pro-issue] about switching to Sidekiq Pro, thinking it would be hard to use in practice. Still, it's possible the benefits could outweigh the drawbacks.

[sidekiq-reliability]: https://github.com/mperham/sidekiq/wiki/Reliability#using-super_fetch
[send-email-worker]: https://github.com/alphagov/email-alert-api/blob/101f813d97c3838199e40643e681f1aca6adf67b/app/workers/send_email_worker.rb
[icinga-memory]: https://github.com/alphagov/govuk-puppet/blob/1258fc65da264191d01b4280cd4422f90085c371/modules/monitoring/files/usr/local/bin/event_handlers/govuk_app_high_memory.sh#L22
[travel-advice-alert]: https://github.com/alphagov/govuk-puppet/blob/be2e3733d9cad619d9cf57e19b190cd5d6116342/modules/govuk_jenkins/manifests/jobs/email_alert_check.pp
[email-status]: https://github.com/alphagov/email-alert-api/blob/101f813d97c3838199e40643e681f1aca6adf67b/app/services/send_email_service/send_notify_email.rb#L23
[sidekiq-pro-issue]: https://github.com/mperham/sidekiq/issues/4612

## Decision

We decided to implement a new [worker][recovery-worker] to find lost work and recreate the jobs to process it. This resolves both of the above issues with lost work, and [codifies][old-recovery-steps] previously manual recovery steps.

Since there is little urgency around sending email, we decided to run the worker only infrequently (currently [every half hour][recovery-schedule]), for work that's [over an hour old][recovery-threshold] - we expect most work to have been processed within an hour.

An edge case for recovery is the initiation of the [daily][daily-init] and [weekly][weekly-init] digest runs. If one of these scheduled jobs is lost before it can [create][digest-run-create] a DigestRun record, our normal recovery strategy won't work. For this scenario, we decided to have a [separate][digest-init-recovery] recovery strategy that's coupled to the [schedule][digest-schedule] for the initiator jobs. The strategy involves looking back over the previous week to see if any DigestRun records are missing for that period.

[recovery-worker]: https://github.com/alphagov/email-alert-api/blob/101f813d97c3838199e40643e681f1aca6adf67b/app/workers/recover_lost_jobs_worker.rb
[old-recovery-steps]: https://github.com/alphagov/govuk-developer-docs/pull/2655/files#diff-5c45975421e97303862e304bf6be30e36fb0384a3d469f15e4fb3f8b71f75f52L47
[recovery-schedule]: https://github.com/alphagov/email-alert-api/blob/59c37a1571d1564d1c63fd913274c810b0742ee6/config/sidekiq.yml#L39
[recovery-threshold]: https://github.com/alphagov/email-alert-api/blob/ea21e7cfd4f6131e2db55e45b923dee3895b081a/app/workers/recover_lost_jobs_worker/unprocessed_check.rb#L13
[daily-init]: https://github.com/alphagov/email-alert-api/blob/bae78a3cb7e970d290d4a95613149c1d5d34e4f1/app/workers/daily_digest_initiator_worker.rb
[weekly-init]: https://github.com/alphagov/email-alert-api/blob/bae78a3cb7e970d290d4a95613149c1d5d34e4f1/app/workers/weekly_digest_initiator_worker.rb
[digest-init-recovery]: https://github.com/alphagov/email-alert-api/blob/bae78a3cb7e970d290d4a95613149c1d5d34e4f1/app/workers/recover_lost_jobs_worker/missing_digest_runs_check.rb
[digest-schedule]: https://github.com/alphagov/email-alert-api/blob/fe6ce7a61fa8ab6692786086c91d4d6017c9b2fa/config/sidekiq.yml#L17-L22
[digest-run-create]: https://github.com/alphagov/email-alert-api/blob/fe6ce7a61fa8ab6692786086c91d4d6017c9b2fa/app/services/digest_initiator_service.rb#L8

## Status

Accepted

## Consequences

### Potential for duplicate work

It's possible we may recreate jobs that still exist in the system. For example, a job that's over an hour old may simply be delayed due to an unusually high backlog in its Sidekiq queue. Although we could check the state of Sidekiq as part of finding lost work, it's still possible to have race conditions where we falsely requeue work that's not lost. To cope with this, we modified each job so that it's idempotent. We used two approaches for this:

- For slow jobs, like processing a content change, we used non-blocking [advisory locks][advisory-lock]. This means any in-progress work that's been incorrectly recovered will be processed quickly as a [no-op][advisory-timeout].

- For fast, high volume jobs, like sending an email, we use a blocking, [row-level lock][email-lock] inside a transaction. Using a row-level lock is faster because the lock is part of the `SELECT` (... `FOR UPDATE`) statement we already execute to fetch the Email record. This is better for the common case, where there is no duplicate work. Even if duplicate work exists, it will only occupy a worker for a short time, until the original job completes and the lock is released.


While making jobs idempotent means the system will behave correctly in the long term, in the short term it's still possible for the recovery to generate an alarming amount of "no-op" work on a queue e.g. if the system is running slowly. This is a particular concern for jobs to send email, where the queue latency can exceed one hour, with many thousands of fresh jobs in the queue. We used [SidekiqUniqueJobs][sidekiq-unique-jobs] to [prevent][email-unique-jobs] a snowball effect in this scenario.

[email-lock]: https://github.com/alphagov/email-alert-api/blob/ea21e7cfd4f6131e2db55e45b923dee3895b081a/app/workers/send_email_worker.rb#L26
[advisory-lock]: https://github.com/alphagov/email-alert-api/blob/59c37a1571d1564d1c63fd913274c810b0742ee6/app/workers/process_content_change_worker.rb#L5
[sidekiq-unique-jobs]: https://github.com/mhenrixon/sidekiq-unique-jobs
[email-unique-jobs]: https://github.com/alphagov/email-alert-api/commit/ac08a4fdbcd691693dc9123e2902be451a4da69d
[advisory-timeout]: https://github.com/alphagov/email-alert-api/blob/fe6ce7a61fa8ab6692786086c91d4d6017c9b2fa/app/workers/application_worker.rb#L7

### Competing with Sidekiq retries

In creating the recovery worker we realised it would be in competition with the [retries][email-sidekiq-retry] we have setup for jobs (or by [default][default-sidekiq-retry]). Sidekiq retries are faster than recovery, so it makes sense to continue using them.

However, the recovery worker could still generate a relatively large backlog of retrying work, if a job is perpetually failing due to a bug. We have tried to mitigate this by [limiting][limited-retries] the number of retries for each job, but we could also consider using the [unique jobs approach][email-unique-jobs] for emails if this isn't enough. In the long term, we also plan to [improve the alerts][alert-adr] for the system, so that we can intervene in good time if work appears to be perpetually failing.

[email-sidekiq-retry]: https://github.com/alphagov/email-alert-api/blob/ea21e7cfd4f6131e2db55e45b923dee3895b081a/app/workers/send_email_worker.rb#L11
[default-sidekiq-retry]: https://github.com/mperham/sidekiq/wiki/Job-Lifecycle
[limited-retries]: https://github.com/alphagov/email-alert-api/pull/1495/commits/df501d3edb7185ce35ab5592489765ec3699dae5

### Delay in processing lost work

In the worst case, it could take up to 1.5 hours to recover a piece of lost work. This is something we could tune if necessary e.g. for transactional emails, which should be sent within [15 minutes][transactional-delay]. We plan to consider this as part of our work on [improving the alerts][alert-adr] for the system. We also plan to reconsider using Sidekiq Pro as a more lightweight solution to speedy recovery, with the recovery worker as a fallback.

[transactional-delay]: https://github.com/alphagov/email-alert-frontend/blob/de1caeea8098eccbb34d8768d7f2c95e455d901c/config/locales/subscriber_authentication.yml#L21
[alert-adr]: https://github.com/alphagov/email-alert-api/blob/master/docs/adr/adr-008-monitoring-and-alerting.md

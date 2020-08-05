# Queues

Email Alert API uses [Sidekiq] to process workers. There are numerous queues configured in the [config/sidekiq.yml] file.

Each queue is assigned a priority and workers will be [picked from the queues according to their priority weighting](queue-priority). The queues listed below are in priority order, although for the specific weightings it's best to refer to the configuration file linked to above.

[Sidekiq]: https://sidekiq.org/
[config/sidekiq.yml]: https://github.com/alphagov/email-alert-api/blob/master/config/sidekiq.yml
[queue-priority]: https://github.com/mperham/sidekiq/wiki/Advanced-Options#queues

## `delivery_transactional`

Used to send one-off emails, such as subscription confirmation.

## `delivery_immediate_high`

Used to send high priority emails to users who have requested immediate updates to content. Foreign travel advice is an example of high priority content.

## `delivery_immediate`

Used to send emails to users who have requested immediate updates to content.

## `process_and_generate_emails`

Used to generate the emails for each content change to users who have requested immediate updates to content. Once the generation process is complete, delivery jobs are sent to either the high priority or normal priority delivery queues.

## `delivery_digest`

Used to send digest emails to users who have requested either daily or weekly updates to content.

## `email_generation_digest`

Used to generate the emails for each content change to users who have requested daily or weekly updates to content. The jobs on this queue are scheduled to run every day at 8:30am for daily updates and every Saturday at 8:30am for weekly updates.

## `default`

Default queue for Sidekiq which we use to perform various miscellaneous operations. This currently includes initiating digest runs (daily and weekly) and then marking them as complete, monitoring and tidying up the database and recovering lost Sidekiq jobs.

[analytics]: analytics.md

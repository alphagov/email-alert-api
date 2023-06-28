# Support tasks

Users can manage email subscribers via the [administration interface on GOV.UK][email-manage].
Support tickets coming through to 2ndline where the user is unaware of this,
or needs guidance, can be assigned to "2nd Line--User Support Escalation".

> **Note**
>
> This applies only to emails sent by GOV.UK.
> [Drug safety updates][drug-updates] are sent manually by MHRA, who manage
> their own service using Govdelivery. We do not have access to this.

If it is not possible for changes to be managed by the user, it is
possible for changes to be made manually. The following rake tasks
should be run using the Jenkins `Run rake task` job for ease-of-use:

[email-manage]: https://www.gov.uk/email/manage
[drug-updates]: https://www.gov.uk/drug-safety-update

## Change a subscriber's email address

This task changes a subscriber's email address.

```bash
$ bundle exec rake support:change_email_address[<old_email_address>, <new_email_address>]
```

## View subscriber's recent emails

This task shows the most recent emails for the given user.
It takes two parameters: `email_address` (required), and `limit` (optional).
`limit` defaults to 10, but you can override this if you need to see more of
the user's history.

```bash
$ bundle exec rake support:view_emails[<email_address>,<limit>]
```

## View subscriber's subscriptions

This task shows you all of the active and inactive subscriptions for a given user.

```bash
$ bundle exec rake support:view_subscriptions[<email_address>]
```

## Unsubscribe a subscriber from a specific subscription

This task unsubscribes one subscriber from a subscription, given an email address and a subscriber list slug.
You can find out the slug of the subscriber list by running the `view_subscriptions` rake task. above

```bash
$ bundle exec rake support:unsubscribe_single_subscription[<email_address>,<subscriber_list_slug>]
```

## Unsubscribe a subscriber from all emails

This task unsubscribes one subscriber from everything they have subscribed to.

```bash
$ bundle exec rake support:unsubscribe_all_subscriptions[<email_address>]
```

## Send a test email

To send a test email to an email address (doesn't have to be subscribed to anything):

```bash
$ bundle exec rake support:send_test_email[<email_address>]
```

## Resend failed emails

There are two Rake tasks available to resend emails which didn't send for
whatever reason and ended up in the failed state. This is most useful after
an incident to resend all emails that failed with a technical failure.

### Using a date range

```bash
bundle exec rake 'support:resend_failed_emails:by_date[<from_date>,<to_date>]'
```

The date format should be in ISO8601 format, for example `2020-01-01T10:00:00Z`.
Depending on the number of emails to send, the Rake task can take a few minutes to run.

### Using email IDs

```bash
bundle exec rake 'support:resend_failed_emails:by_id[<email_one_id>,<email_two_id>]'
```

## Get subscriber list csv report

To see a csv report for the number of subscribers for a given list:

```bash
bundle exec rake 'report:csv_subscriber_lists[<on_date>] SLUGS=<list_slug>'
```

The date should be in ISO8601 format, for example 2020-01-01.

## Get a simple count of subscribers to a list by its URL

To see a simple count of the number of subscribers for a given list:

```bash
bundle exec rake 'report:csv_subscriber_lists[<path>,<active_on_date (optional)>]'
```
This will report on the number of active subscriptions for a given path.

> **Warning**
>
> This is called simple because it only gets subscriber lists for a direct path. There may still be subscriptions by topic or link, so finding an empty or missing subcription list does not mean that no-one will receive email updates about that page! See below for a more detailed description of how to get the subscriber list.

The path should be the full path on gov.uk (for instance /government/statistics/examples if the page you're interested in is https://www.gov.uk/government/statistics/examples)

You can also pass it a :active_on_datetime which will count how many active subscriptions there were at the end of the day on a particular date. The active_on_date defaults to today if not specified, and should be in ISO8601 format, for example 2022-03-03T12:12:16+00:00. The time will always be rounded to the end of the day, even if that is in the future.

## Finding all subscriber lists that match a given page.

The previous rake task only gets subscriber lists that match a URL. But subscribers can match on topics/tags/links, so to get a full idea of how many people subscribe to a page you will need to access the console:

```bash
gds govuk connect -e integration app-console email-alert-api
```

..then you can create a SubscriberListQuery. If an email has already been sent out for a page, you can query the ContentChange item for that email:


```
cc = ContentChange.where(base_path: '/government/publications/my-publication').first
```

...then use that to build a SubscriberlistQuery:

```
lists = SubscriberListQuery.new(content_id: cc.content_id, tags: cc.tags, links: cc.links, document_type: cc.document_type, email_document_supertype: cc.email_document_supertype, government_document_supertype: cc.government_document_supertype).lists

total_subs = lists.sum { |l| l.subscriptions.active.count }

# Broken down by frequency:

immediately_subs = lists.sum { |l| l.subscriptions.active.immediately.count }
daily_subs = lists.sum { |l| l.subscriptions.active.daily.count }
weekly_subs = lists.sum { |l| l.subscriptions.active.weekly.count }

```

If an email hasn't already been sent out, you will need to console into an app that has access to the Content Store and find the values for the SubscriberListQuery manually and copy/paste them across.

## Get a report of single page notification subscriber lists by active subscriber count

This report provides a count of all subscriber lists with a content ID, followed by individual subscriber lists ordered by active subscriber count.

```bash
bundle exec rake 'report:single_page_notifications_top_subscriber_lists'
```

By default output is limited to only show the top 25 lists by active subscriber count. However
that can be overridden to increase or decrease the output number.

```bash
bundle exec rake 'report:single_page_notifications_top_subscriber_lists[5]'
```

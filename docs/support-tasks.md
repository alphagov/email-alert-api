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
possible for changes to be made manually. The following rake tasks should be
run using the `kubectl` command, as described in the [EKS documentation][eks-docs].

[email-manage]: https://www.gov.uk/email/manage
[drug-updates]: https://www.gov.uk/drug-safety-update
[eks-docs]: https://docs.publishing.service.gov.uk/kubernetes/cheatsheet.html

## Change a subscriber's email address

This task changes a subscriber's email address.

```bash
$ kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake support:change_email_address[<old_email_address>, <new_email_address>]
```

## View subscriber's recent emails

This task shows the most recent emails for the given user.
It takes two parameters: `email_address` (required), and `limit` (optional).
`limit` defaults to 10, but you can override this if you need to see more of
the user's history.

```bash
$ kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake support:view_emails[<email_address>,<limit>]
```

## View subscriber's subscriptions

This task shows you all of the active and inactive subscriptions for a given user.

```bash
$ kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake support:view_subscriptions[<email_address>]
```

## Unsubscribe a subscriber from a specific subscription

This task unsubscribes one subscriber from a subscription, given an email address and a subscriber list slug.
You can find out the slug of the subscriber list by running the `view_subscriptions` rake task. above

```bash
$ kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake support:unsubscribe_single_subscription[<email_address>,<subscriber_list_slug>]
```

## Unsubscribe all subscribers from a specific subscription

This task unsubscribes all active subscribers from a subscription, given a subscriber list slug.

```bash
$ kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake support:unsubscribe_all_subscribers_from_subscription[<subscriber_list_slug>]
```

## Unsubscribe a subscriber from all emails

This task unsubscribes one subscriber from everything they have subscribed to.

```bash
$ kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake support:unsubscribe_all_subscriptions[<email_address>]
```

## Send a test email

To send a test email to an email address (doesn't have to be subscribed to anything):

```bash
$ kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake support:send_test_email[<email_address>]
```

## Resend failed emails

There are two Rake tasks available to resend emails which didn't send for
whatever reason and ended up in the failed state. This is most useful after
an incident to resend all emails that failed with a technical failure.

### Using a date range

```bash
kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake 'support:resend_failed_emails:by_date[<from_date>,<to_date>]'
```

The date format should be in ISO8601 format, for example `2020-01-01T10:00:00Z`.
Depending on the number of emails to send, the Rake task can take a few minutes to run.

### Using email IDs

```bash
kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake 'support:resend_failed_emails:by_id[<email_one_id>,<email_two_id>]'
```

## Get subscriber list csv report

To see a csv report for the number of subscribers for a given list:

```bash
kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake 'report:csv_subscriber_lists[<on_date>] SLUGS=<list_slug>'
```

The date should be in ISO8601 format, for example 2020-01-01.

## Get a simple count of subscribers to a list by its URL

To see a simple count of the number of subscribers for a given list:

```bash
kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake 'report:subscriber_list_subscriber_count[<path>,<active_on_date (optional)>]'
```
This will report on the number of active subscriptions for a given path.

> **Warning**
>
> This is called simple because it only gets subscriber lists for a direct path. There may still be subscriptions by topic or link, so finding an empty or missing subcription list does not mean that no-one will receive email updates about that page! See below for a more detailed description of how to get the subscriber list.
> It also won't work that well if the path is a finder. See below for better tasks for finders or detailed subscriber lists.

The path should be the full path on gov.uk (for instance /government/statistics/examples if the page you're interested in is https://www.gov.uk/government/statistics/examples)

You can also pass it a :active_on_datetime which will count how many active subscriptions there were at the end of the day on a particular date. The active_on_date defaults to today if not specified, and should be in ISO8601 format, for example 2022-03-03T12:12:16+00:00. The time will always be rounded to the end of the day, even if that is in the future.

## Get stats for subscribers to a finder by its URL

To see a report on the number of subscribers to a finder, :

```bash
kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake 'report:finder_statistics[<path>]'
```
This will report on the number of subscriber lists to the finder on a given path.

The path should be the full path on gov.uk (for instance /cma-cases if the page you're interested in is https://www.gov.uk/cma-cases)

Because finder subscriptions can include the filters active on the finder at the point the subscription was created, there may be more than one subscriber list. Finders require an email_alert_signup item in the links section of their content item to allow alerts, so if there are no subscriptions to a finder
it may be because it cannot be signed up to.


## Finding out how many messages were sent when a page changed

The previous rake task only gets subscriber lists that match a URL. But subscribers can match on topics/tags/links, so to get a full idea of how many people subscribe to a page:

```bash
kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake 'report:historical_content_change_statistics[<path>]'
```

This gives you a list of all the content changes that have been registered for that path - this is all the times that email-alert-api actually sent out notifications, with a breakdown for each occurence into the number of people notified immediately, in the next daily digest, and in the weekly digest.

## Finding out how many messages would be sent if a page were changed

The previous rake task is only useful once emails have gone out. Occasinally you might be asked for details of how many people will be notified if a major change is published to a document. You can find that out with this task:

```bash
kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake 'report:future_content_change_statistics[<path>,<use draft store?>]'
```

The second parameter should be true or false depending on whether you want to use information from the draft or live content stores (note that the most common thing that will change the number of subscriber lists notified are the links and organisations, and if changed they occur immediately, and do not differ on the draft and live stores).

## Get a report of single page notification subscriber lists by active subscriber count

This report provides a count of all subscriber lists with a content ID, followed by individual subscriber lists ordered by active subscriber count.

```bash
kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake 'report:single_page_notifications_top_subscriber_lists'
```

By default output is limited to only show the top 25 lists by active subscriber count. However
that can be overridden to increase or decrease the output number.

```bash
kubectl -n apps exec -it deploy/email-alert-api -- bundle exec rake 'report:single_page_notifications_top_subscriber_lists[5]'
```

## Find out sent/delivered stats for a specific Content ID:

```bash
kubectl -n apps exec it deploy/email-alert-api -- bundle exec rake 'support:emails:stats_for_content_id[<CONTENT ID>,<START_DATE (optional)>,<END_DATE (optional)>]'
```

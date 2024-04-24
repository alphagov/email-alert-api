# Subscriber List Audit

## Background

At the moment it's possible to get into a state where subscriber lists exist
but cannot be triggered:
- if the keys or fields used to trigger the list are out-of-date with real
  content,
- if a format is fully retired without the correct manual intervention to
  clean up the lists,
- if content is unpublished and the automatic list cleanup code fails.

To determine whether untriggerable lists exist, we can run an audit over the
gov.uk website using the sitemap. We iterate over the sitemap, getting the
content item for each path and then comparing it against the EmailAlertCriteria
(to check if the path would _ever_ trigger a subscriber list), then if it passes
that test against the ContentItemListQuery, which returns a list of SubscriberLists
that would be triggered by major changes to that path. For each of those
SubscriberLists, we update a last_audited_at field with the time the audit started.
At the end of the process, any list that has an empty last_audited_at field or
where the field is older than the time the audit started must not have been marked,
so we know that it can't be triggered.

## Running the audit

This is a long-running job which needs to be run asynchronously. To kick it off, use:

```bash
kubectl -n apps exec -it deploy/email-alert-api -- rake 'subscriber_list_audit:start'
```

NB: It will probably only reliably run in production, as the time taken to iterate
over the sight may be more than a day, which in integration will be interrupted
by the environment sync.

To check the number of workers remaining on the job:

```bash
kubectl -n apps exec -it deploy/email-alert-api -- rake 'subscriber_list_audit:queue_size'
```

When there are no workers remaining, you can run:

```bash
kubectl -n apps exec -it deploy/email-alert-api -- rake 'subscriber_list_audit:report[2024-04-16]'
```

to get a list of all subscriber lists that have either not been marked in an audit, or have not
been marked in an audit since the specified date.

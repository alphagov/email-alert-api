# Send a bulk email

Sometimes it may be necessary to send a bulk email to many subscribers at once.
There is [a Rake task in email-alert-api][rake-task] to perform this task.
You may want to create a temporary rake task instead, see [this example](https://github.com/alphagov/email-alert-api/commit/05ff8fb824690e0a086e0d6ac03c16e80ef90b59).

[rake-task]: https://github.com/alphagov/email-alert-api/blob/main/lib/tasks/bulk_email.rake

## 1. Prepare the content

You'll need:

- Email subject line
- Email body text

The body text can contain [a limited subset of markdown][notify-markdown]. A footer will be automatically appended to the body text. The footer will have links to unsubscribe and manage subscriptions. We should always provide users with these options, to help avoid our emails being marked as spam.

Any occurrence of `%LISTURL%` in the body text will be substituted with the URL of the subscriber list, or an empty string if it has none. This is useful when sending the same email across many lists, where the content of the email needs to link to the specific page on GOV.UK associated with the list. You should check the lists you want to send a bulk email for, to see if they have a URL populated (it's a recent addition).

[notify-markdown]: https://www.notifications.service.gov.uk/using-notify/guidance/edit-and-format-messages

## 2. Get the subscriber lists

Next you'll need to get the IDs of all the subscriber lists to send the email
out to. This will require querying the email-alert-api `SubscriberList` model.

If you have the mailing list's slug (e.g. from the query string on the email
signup pages):

```rb
> SubscriberList.find_by(slug: "your-slug").id
```

For a more complex query, for example to get the IDs of all the subscriber
lists for travel advice, you could use the following query:

```rb
> SubscriberList.where("links->'countries' IS NOT NULL").pluck(:id)
```

## 3. Send a test email

Use [the Send bulk emails job in Staging][send-bulk-staging] to send the email.

**Make sure you know [how to receive emails in Staging][staging-emails].**

[send-bulk-staging]: https://deploy.blue.staging.govuk.digital/job/send-bulk-email/
[staging-emails]: https://docs.publishing.service.gov.uk/repos/email-alert-api/receiving-emails-from-email-alert-api-in-integration-and-staging.html

## 4. Send the real email

Use [the Send bulk emails job in Production][send-bulk-production] to send the email.

[send-bulk-production]: https://deploy.blue.production.govuk.digital/job/send-bulk-email/

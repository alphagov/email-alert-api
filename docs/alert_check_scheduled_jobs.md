# Alert Check Scheduled Jobs

Two sets of alerts (Medical Safety Alerts and Travel Advice Alerts) are critical, so it's important to check that they have gone out correctly. To do this we have a pair of scheduled sidekiq jobs. These jobs use the public search API to find a list of relevant Content IDs, then iterate that list checking for the existence of at least one Email record which has that Content ID and a notify_status of "delivered", and which was created after the public update time . Via the prometheus collector, we return metrics of the number of alerts and the number of alerts that have at least one delivery record. Ideally those number should be the same (0 & 0 is okay, 2 & 2 is okay, but 2 & 1 is an alert state).

The jobs run every 15 minutes, and checks for alerts that meet the following criteria from the Search API results:
- document type is `medical_safety_alert` or `travel_advice`
- is in the 50 most recently updated documents of that type
- created at least one hour ago (very new alerts are excluded)
- created no more than 2 days ago (older alerts are excluded)

## Multiple changes to a content item

It is possible that a given travel advice item or medical alert might be updated more than once in two days, but there's no way to know about that through the Search API (we can only find out the last update to a given page). In this case we can only check that emails were delivered after the last public update. The 1 hour lag before an alert becomes checkable plus the 15 minute update frequency means that if a change happens between 60 and 75 minutes after the previous change the system can only confirms that emails were sent out for the most recent update, and if further proof of the previous update is needed a developer will have to check that manually. If the change happens later than 75 minutes, both changes will have been checked by separate runs of the job.

## Dependencies

This system depends on the Search API structure, so radical changes to the search API's results format may cause problems.

## Manual Checking

There is a rake task to create a subscriber to both the medical and travel alerts. In production this account will persist, but if you want to use it in integration you will need to run the task before testing, because integration can only send to one email, and the email anonymisation process during database syncing will remove that one email address.

```
kubectl config use-context govuk-<ENVIRONMENT>
kubectl -n apps deploy/email-alert-api -- rake 'alert_listeners:verify_or_create'
```

The listener subscribers receive emails into google group accounts:
- Production: email-alert-api-alert-listener@digital.cabinet-office.gov.uk
- Staging: email-alert-api-staging@digital.cabinet-office-gov.uk
- Integration: email-alert-api-integration@digital.cabinet-office-gov.uk

See also [Receive emails from Email Alert API in Integration and Staging](receiving-emails-from-email-alert-api-in-integration-and-staging.md)

## Testing

To test the alert in integration, you will need to run the task above (to create the listener), then create a medical alert or travel advice update, and wait one hour. You should see no alert initially (because hopefully the integration listener account will have received the email). To trigger the alert, first find out the content id of the alert  you have just publised, then open the console and update the emails for that

```
kubectl config use-context govuk-integration
kubectl -n apps deploy/email-alert-api -- rails c

(Rails console)
> emails = Email.where(content_id: <your content id> notify_status: "delivered")
> emails.each { |eml| eml.notify_status = nil; eml.save }
> AlertCheckWorker.new.perform(<your document type, either "medical_safety_alert" or "travel_advice|>)
```

This will clear the delivered status for the email, and run the alert check worker. Prometheus should collect the metrics after a minute, and set off the alert.

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

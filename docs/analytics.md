# Analytics

Email Alert API does not currently have an automated means to generate analytics and data insights. Instead, we rely on a small number of manual rake tasks, which run on data stored in [the database][schema.rb].

> See "[data cleanup mechanisms](data-cleanup-mechanisms.md)" for information about how long we retain data in the system.

[schema.rb]: https://github.com/alphagov/email-alert-api/tree/master/db/schema.rb

## Subscription data for each subscriber list

This generates a CSV report about each subscriber list, for a specific date. In order to help disambiguate between lists with similar titles, by default each row of the report includes all of the [matching criteria](matching-content-to-subscriber-lists.md) for a list.

```bash
report:csv_subscriber_lists["2020-11-05"]

# or for specific lists
SLUGS=living-in-spain,living-in-italy report:csv_subscriber_lists["2020-11-05"]

# or with tags containing a string
TAGS_PATTERN=country report:csv_subscriber_lists["2020-11-05"]

# or with links containing a string
LINKS_PATTERN=countries report:csv_subscriber_lists["2020-11-05"]
```

If you want just some specific headers, you can choose which headers you want as follows:
```bash
HEADERS=title,individual_subscribers,daily_subscribers,weekly_subscribers,total_subscribers report:csv_subscriber_lists["2020-11-05"]
```
All available headers are used by default, pass in the name of the headers as they are in the first row of the default output

[⚙ Run rake task on Integration][rake-csv-subscriber-lists]

[rake-csv-subscriber-lists]: https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:csv_subscriber_lists


[⚙ Run rake task with limited number of headers on Integration][rake-csv-subscriber-lists-limited-number-headers]

[rake-csv-subscriber-lists-limited-number-headers]: https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=HEADERS=title,individual_subscribers,daily_subscribers,weekly_subscribers,total_subscribers%20report:csv_subscriber_lists

## Content changes for each subscriber list

This generates a CSV report of matched content changes over the last week.

```bash
report:matched_content_changes

# or with a specific range
START_DATE=2020-08-07 END_DATE=2020-08-13 report:matched_content_changes
```

[⚙ Run rake task on Integration][rake-matched-content-changes]

[rake-matched-content-changes]: https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:matched_content_changes

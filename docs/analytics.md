# Analytics

Email Alert API does not currently have an automated means to generate analytics and data insights. Instead, we rely on a small number of manual rake tasks, which run on data stored in [the database][schema.rb].

> See "[data cleanup mechanisms](data-cleanup-mechanisms.md)" for information about how long we retain data in the system.

[schema.rb]: https://github.com/alphagov/email-alert-api/tree/master/db/schema.rb

## Subscription data for each subscriber list

This generates a CSV report about each subscriber list, for a specific date. In order to help disambiguate between lists with similar titles, each row of the report includes all of the [matching criteria](matching-content-to-subscriber-lists.md) for a list.

```bash
report:csv_subscriber_lists["2020-11-05"]

# or for specific lists
SLUGS=living-in-spain,living-in-italy report:csv_subscriber_lists["2020-11-05"]

# or with tags containing a string
TAGS_PATTERN=brexit_checklist_criteria report:csv_subscriber_lists["2020-11-05"]

# or with links containing a string
LINKS_PATTERN=countries report:csv_subscriber_lists["2020-11-05"]
```

[⚙ Run rake task on Integration][rake-csv-subscriber-lists]

[rake-csv-subscriber-lists]: https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:csv_subscriber_lists

## Content changes for each subscriber list

This generates a CSV report of matched content changes over the last week.

```bash
report:matched_content_changes

# or with a specific range
START_DATE=2020-08-07 END_DATE=2020-08-13 report:matched_content_changes
```

[⚙ Run rake task on Integration][rake-matched-content-changes]

[rake-matched-content-changes]: https://deploy.integration.publishing.service.gov.uk/job/run-rake-task/parambuild/?TARGET_APPLICATION=email-alert-api&MACHINE_CLASS=email_alert_api&RAKE_TASK=report:matched_content_changes

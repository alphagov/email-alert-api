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

## Content changes for each subscriber list

This generates a CSV report of matched content changes over the last week.

```bash
report:matched_content_changes

# or with a specific range
START_DATE=2020-08-07 END_DATE=2020-08-13 report:matched_content_changes
```

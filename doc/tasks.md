# Tasks

## Send a test email

To send a test email to an existing subscriber:

```bash
$ bundle exec rake deliver:to_subscriber[<subscriber_id>]
```

To send a test email to an email address (doesn't have to be subscribed to anything):

```bash
$ bundle exec rake deliver:to_test_email[<email_address>]
```

## Change a subscriber's email address

This task changes a subscriber's email address.

```bash
$ bundle exec rake manage:change_email_address[<old_email_address>, <new_email_address>]
```

## Manually unsubscribe subscribers

This task unsubscribes one or more subscribers from everything they
have subscribed to.

To unsubscribe a single subscriber:

```bash
$ bundle exec rake manage:unsubscribe_single[<email_address>]
```

To unsubscribe a set of subscribers in bulk from a CSV file:

```bash
$ bundle exec rake manage:unsubscribe_bulk_from_csv[<path_to_csv_file>]
```

The CSV file should have email addresses in the first column. All
other columns will be ignored.

## Move subscribers from one list to another

This task moves all subscribers from one subscriber list to another one.
It is useful for organisation or taxonomy changes.

```bash
$ bundle exec rake manage:move_all_subscribers[<from_slug>, <to_slug>]
```

You need to supply the `slug` for the source and destination
subscriber lists.

## Export data

There are a number of tasks available which export subscriber list data into CSV files on standard output. In
particular this includes the active subscription count.

```bash
$ bundle exec rake export:csv_from_ids[<subscriber_list_id>, ...]
```

```bash
$ bundle exec rake export:csv_from_ids_at[<date>, <subscriber_list_id>, ...]
```

This is the same as above, but exports the active subscription count of the subscriber list as it was on a particular
date.

```bash
$ bundle exec rake export:csv_from_living_in_europe
```

This is a convenience export which does the same as above but with all the "Living in Europe" taxon subscriber lists
without needing to know their IDs.

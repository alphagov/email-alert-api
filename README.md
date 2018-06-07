# email-alert-api

Sends emails to users that subscribe to specific GOV.UK email alerts.

Provides a consistent internal interface to external email
notification services. Currently supports only [GOV.UK Notify](https://www.notifications.service.gov.uk/).

Given a tagged publication event, it sends email alerts for
subscribers to those tags via the external services.

## Nomenclature

- **Content change**:
  * A publication event that creates or changes a content item
  * The representation of that event for the purpose of sending emails

- **Delivery attempt**:
  * An attempt to send a generated email to a subscriber using the external email notification services
  * Can be multiple attempts per email if there are errors

- **Digest run**:
  * One batch of either daily or weekly digests representing a particular subscription that has a start and end time and a set of subscribers to send emails to

- **Email**:
  * An email generated from one or more content changes with a subject line and body, to be sent to subscribers

- **Matched content change**:
  * A content change that has been matched to a set of subscribers who will receive an email about it

- **Subscriber list**:
  * A set of criteria that users can subscribe to in order to receive emails (eg. all publications by HMRC)

- **Subscriber**:
  * A user who has subscribed to one or more subscriber lists

- **Subscription**:
  * The relationship between a subscriber and the subscription lists they are subscribed to

## Technical documentation

### Dependencies

* PostgreSQL database (9.3 or higher - requires `json` with `json_object_keys` method)
* Redis (for [Sidekiq](http://sidekiq.org/))
* GOV.UK Notify API key and other details (see
  [`email_service.yml`](config/email_service.yml) for required fields)

### Initial setup

* Check that the configuration in `config/database.yml` is correct
* Run `bundle exec rake db:setup` to load the database

### Running the application

```bash
$ ./startup.sh
```

* email-alert-api runs on port 3088
* sidekiq-monitoring for email-alert-api uses 3089

### Running the test suite

* Run `RAILS_ENV=test bundle exec rake db:setup` to load the database
* Run `bundle exec rspec` to run the tests

### Using test email addresses for signup

Using any email address that ends with `@notifications.service.gov.uk`
will not create a subscriber or a subscription, however will return a `201 Created` response.

### Fixing "PG::InsufficientPrivilege" error in the development VM

email-alert-api relies on PostgreSQL's `uuid-ossp` module. This is not
available by default and you might find running migrations results in
the following error:

```
PG::InsufficientPrivilege: ERROR:  permission denied to create extension "uuid-ossp"
```

This can be solved by:

```bash
> sudo -upostgres psql email-alert-api_development
psql> CREATE EXTENSION "uuid-ossp";
```

and then repeating for `email-alert-api_test`.

### Tasks

#### Send a test email

To send a test email to an existing subscriber:

```bash
$ bundle exec rake deliver:to_subscriber[<subscriber_id>]
```

To send a test email to an email address (doesn't have to be subscribed to anything):

```bash
$ bundle exec rake deliver:to_test_email[<email_address>]
```

#### Change a subscriber's email address

This task changes a subscriber's email address.

```bash
$ bundle exec rake manage:change_email_address[<old_email_address>, <new_email_address>]
```

#### Manually unsubscribe subscribers

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

#### Move subscribers from one list to another

This task moves all subscribers from one subscriber list to another one.
It is useful for organisation or taxonomy changes.

```bash
$ bundle exec rake manage:move_all_subscribers[<from_slug>, <to_slug>]
```

You need to supply the `slug` for the source and destination
subscriber lists.

#### Export data

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

### Available endpoints

#### application API

* `GET /subscriber-lists?tags[organisation]=cabinet-office` - gets a stored subscriber list that's relevant to just the `cabinet-office` organisation, in the form:

```json
{
  "subscriber_list": {
    "id": "an id",
    "title": "Title of topic",
    "subscription_url": "https://public-url/subscribe-here?topic_id=123",
    "gov_delivery_id": "123",
    "document_type": "",
    "created_at": "20141010T12:00:00",
    "updated_at": "20141010T12:00:00",
    "tags": {
      "topics": ["topic-slug"]
    }
  }
}
```

* `POST /subscriber-lists` with data:

```json
{
  "title": "My title",
  "tags": {
    "organisations": ["my-org"]
  }
}
```

and it will respond with the JSON response for the `GET` call above.

* `POST /notifications` with data:

```json
{
  "subject": "This is the subject/title of my bulletin",
  "body": "Email body here",
  "tags": {
    "tag": ["values"]
  }
}
```

and it will respond with `202 Accepted` (the call is queued to prevent
slowness in the external notifications API).

The following fields are accepted on this endpoint: `subject`, `from_address_id`, `urgent`, `header`, `footer`,
`document_type`, `content_id`, `public_updated_at`, `publishing_app`, `email_document_supertype`,
`government_document_supertype`, `title`, `description`, `change_note`, `base_path`, `priority` and `footnote`.

* `GET /subscribers/xxx/subscriptions` - gets a subscriber's subscriptions, in the form:

```json
{
  "subscriber": {
    "id": 1,
    "address": "test@example.com",
    "created_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
    "updated_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
    "signon_user_uid": null,
    "deactivated_at": null
  },
  "subscriptions": [
    {
      "subscriber_id": 1,
      "subscriber_list_id": 4232,
      "created_at": "Wed, 07 Mar 2018 18:52:25 UTC +00:00",
      "updated_at": "Wed, 07 Mar 2018 18:52:25 UTC +00:00",
      "frequency": "daily",
      "signon_user_uid": null,
      "id": "476e1439-f5ba-4d7a-b4aa-1090563c5c36",
      "source": "imported",
      "ended_at": null,
      "ended_reason": null,
      "subscriber_list": {
        "id": 4232,
        "title": "All types of document about all topics by Foreign & Commonwealth Office",
        "created_at": "Thu, 01 Aug 2013 12:53:34 UTC +00:00",
        "updated_at": "Tue, 13 Mar 2018 15:11:29 UTC +00:00",
        "document_type": "",
        "tags": {},
        "links": {
          "organisations": ["9adfc4ed-9f6c-4976-a6d8-18d34356367c"]
        },
        "email_document_supertype": "",
        "government_document_supertype": "",
        "signon_user_uid": null,
        "slug": "all-types-of-document-about-all-topics-by-foreign-commonwealth-office"
      }
    }
  ]
}
```

* `PATCH /subscribers/xxx` with data:

```json
{
  "new_address": "test2@example.com"
}
```

and it will respond with the details of the subscriber including the
new email address.

* `DELETE /subscribers/xxx` - unsubscribes a provided subscriber and returns `204 No Content`.

* `POST /subscriptions` with data:

```json
{
  "address": "email@address.com",
  "subscribable_id": "The id of a subscriber list"
}
```

and it will create a new subscription between the email address and the
subscriber list. It will respond with a `201 Created` if it's a new
subscription or a `200 OK` if the subscription already exists.

* `PATCH /subscriptions/xxxx` with data:

```json
{
  "frequency": "weekly"
}
```

and it will respond with the details of the subscription including the
new frequency.

* `POST /unsubscribe/xxx` - unsubscribes a subscriber from the provided subscription and returns `204 No Content`.

* `POST /subscribers/auth-token` with data:

```json
{
  "address": "test@example.com",
  "destination": "/authentication-page-on-govuk",
  "redirect": "/page-user-wanted-on-govuk",
}
```

This will trigger an email to the address specified with a link to the
destination with a query string of token and a [JWT](https://jwt.io/) token.
Returns a 201 status code on success or 404 if the subscriber is not known
to Email Alert API.

#### healthcheck API

A queue health check endpoint is available at `/healthcheck`.

```json
{
  "checks": {
    "queue_size": {
      "status": "ok"
    },
    "queue_age": {
      "status": "ok"
    }
  },
  "status": "ok"
 }
```

### Manually retrying failed notification jobs

In the event of an outage, the Email Alert API will enqueue failed
notification jobs in the Sidekiq retry queue. The retry queue size
can be viewed via Sidekiq monitoring or by running the following
command in a rails console:

```ruby
Sidekiq::RetrySet.new.size
```

To manually retry all jobs in the retry queue:

```ruby
Sidekiq::RetrySet.new.retry_all
```

See the [Sidekiq docs](https://github.com/mperham/sidekiq/wiki/API)
for more information.

## Licence

[MIT License](LICENCE)

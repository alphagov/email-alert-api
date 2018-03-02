# email-alert-api

Updates users that subscribe to specific GOV.UK email alerts.

Provides a consistent internal interface to external email notification services.
Currently supports only [GovDelivery](http://www.govdelivery.com/).

Given a tagged publication event it sends email alerts for subscribers to those
tags via the external services.

## Nomenclature

- **Subscriber list**:
 * An email subscriber list (the actual email addresses are stored on
  GovDelivery's servers)
 * Associated links/tags and document type and supertype fields indicate what
  the subscribers for that list are interested in and what updates they should
  receive. See the [documentation on matching content to subscriber lists](doc/matching-content-to-subscriber-lists.md)
  for more details.

- **Topic**:
 * GovDelivery terminology for a subscriber list
 * Topics have tags
 * Subscribers receive emails when you "send a bulletin" to that topic

- **Bulletin**:
 * GovDelivery terminology for an email notification

## Technical documentation

### Dependencies

* Postgres database (9.3 or higher - requires `json` with `json_object_keys` method)
* Redis (for [sidekiq](http://sidekiq.org/))
* GovDelivery API login and account (see
  [`gov_delivery.yml`](config/gov_delivery.yml) for required fields)

### Initial setup

* Check that the configuration in `config/database.yml` is right
* Run `bundle exec rake db:setup` to load the database

### Running the application

```bash
$ ./startup.sh
```

email-alert-api runs on port 3088
sidekiq-monitoring for email-alert-api uses 3089

### Running the test suite

* Run `RAILS_ENV=test bundle exec rake db:setup` to load the database
* Run `bundle exec rspec` to run the tests

### PG::InsufficientPrivilege on development VM

Email alert api relies on Postgresql's uuid-ossp module. This is not available
by default and you might find running migrations results in the following error:

```
PG::InsufficientPrivilege: ERROR:  permission denied to create extension "uuid-ossp"
```

This can be solved by:

```
> sudo -upostgres psql email-alert-api_development
psql> CREATE EXTENSION "uuid-ossp";
```

and then repeating for `email-alert-api_test`

### Tasks

#### Import from GovDelivery export

To import the data from a GovDelivery export, you can use a Rake task:

```bash
$ bundle exec rake import_govdelivery_csv[subscriptions.csv,digests.csv]
```

### GovDelivery interaction

GovDelivery client code is stored in `app/services/gov_delivery`.

To connect to the real GovDelivery, you should provide the credentials in
[`gov_delivery.yml`](config/gov_delivery.yml).

## Available endpoints

### application API

* `GET /subscriber-lists?tags[organisation]=cabinet-office` - gets a stored
  subscriber list that's relevant to just the `cabinet-office` organisation, in
  the form:

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

and it will respond with `202 Accepted` (the call is queued to prevent slowness
in the external notifications API).

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

### Using test email addresses for signup

Using any email address that ends with '@notifications.service.gov.uk'
will not create a subscriber or a subscription, however will return a `201 Created`.

### healthcheck API

A queue health check endpoint is available at /healthcheck

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

## GOVUK request id

Email body text is appended with an html element with a data attribute containing the originating request id.
This element is an empty span and will not be visible to the recipient.
Plain text emails will not contain this element as their content is stripped of any html.

### Manually retrying failed notification jobs

In the event of a GovDelivery outage the Email Alert API will enqueue failed notification jobs
in the Sidekiq retry queue.
The retry queue size can be viewed via Sidekiq monitoring or by issuing the following command in a rails console:

```ruby
Sidekiq::RetrySet.new.size
```

To manually retry all jobs in the retry queue:

```ruby
Sidekiq::RetrySet.new.retry_all
```

See the [Sidekiq docs](https://github.com/mperham/sidekiq/wiki/API) for more information.

## Integration & Staging Environments

- [Overview of the Integration & Staging Synchronisation Process](doc/integration-staging-sync.md)

## Licence

[MIT License](LICENCE)

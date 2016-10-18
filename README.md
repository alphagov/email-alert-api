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
 * Associated tags indicate what the subscribers for that list are interested in
  and what updates they should receive
 * An optional document_type indicates the types of notifications that will be
  matched for subscribers. If the list has a document_type set, only
  notifications with a matching document_type will be sent; if the list has
  no document_type, messages will be sent whether or not the notification has
  a document_type.

- **Topic**:
 * GovDelivery terminology for a subscriber list
 * Topics have tags
 * Subscribers receive emails when you "send a bulletin" to that topic

- **Bulletin**:
 * GovDelivery terminology for an email notification

## Technical documentation

### Dependencies

* Postgres database (9.1 or higher - requires `hstore`)
* Redis (for [sidekiq](http://sidekiq.org/))
* GovDelivery API login and account (see
  [`gov_delivery.yml`](config/gov_delivery.yml) for required fields)

### Initial setup

* Check that the configuration in `config/database.yml` is right
* Run `bundle exec rake db:setup` to load the database


### Running the application

`./startup.sh`

email-alert-api runs on port 3088
sidekiq-monitoring for email-alert-api uses 3089

### Running the test suite

* Run `RAILS_ENV=test bundle exec rake db:setup` to load the database
* Run `bundle exec rspec` to run the tests

### GovDelivery interaction

GovDelivery client code is stored in `app/services/gov_delivery`.

To connect to the real GovDelivery, provide the credentials as environment
variables, i.e.:

`GOVDELIVERY_USERNAME=govdelivery@example.com GOVDELIVERY_PASSWORD=nottherealpassword rails s`

or export them using dotenv or similar.

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

### GOVUK request id

Email body text is appended with an html element with a data attribute containing the originating request id.
This element is an empty span and will not be visible to the recipient.
Plain text emails will not contain this element as their content is stripped of any html.

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

### Manually retrying failed notification jobs

In the event of a GovDelivery outage the Email Alert API will enqueue failed notification jobs
in the Sidekiq retry queue.
The retry queue size can be viewed via Sidekiq monitoring or by issuing the following command in a rails console:

```
Sidekiq::RetrySet.new.size
```

To manually retry all jobs in the retry queue:

```
Sidekiq::RetrySet.new.retry_all
```

See the [Sidekiq docs](https://github.com/mperham/sidekiq/wiki/API) for more information.

## Integration & Staging Environments

- [Overview of the Integration & Staging Synchronisation Process](doc/integration-staging-sync.md)

## Licence

[MIT License](LICENCE)

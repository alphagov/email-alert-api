# email-alert-api

Updates users that subscribe to specific GOV.UK email alerts.

Provides a consistent internal interface to external email notification services.
Currently supports only [GovDelivery](http://www.govdelivery.com/).

Given a tagged publication event it sends email alerts for subscribers to those
tags via the external services.

## Dependencies

* Postgres database (9.1 or higher - requires `hstore`)
* Redis (for [sidekiq](http://sidekiq.org/))
* GovDelivery API login and account (see
  [`gov_delivery.yml`](config/gov_delivery.yml) for required fields)

## Nomenclature

### Subscriber list

* An email subscriber list (the actual email addresses are stored on
  GovDelivery's servers)
* Associated tags indicate what the subscribers for that list are interested in
  and what updates they should receive

### Topic

* GovDelivery terminology for a subscriber list
* Topics have tags
* Subscribers receive emails when you "send a bulletin" to that topic

### Bulletin

* GovDelivery terminology for an email notification

## Initial setup

* Check that the configuration in `config/database.yml` is right
* Run `bundle exec rake db:setup` to load the database

## Running the test suite

* Run `RAILS_ENV=test bundle exec rake db:setup` to load the database
* Run `bundle exec rspec` to run the tests

## Running the application

Run `./startup.sh`.

## GovDelivery interaction

GovDelivery client code is stored in `app/services/gov_delivery`.

To connect to the real GovDelivery, provide the credentials as environment
variables, i.e.:

`GOVDELIVERY_USERNAME=govdelivery@example.com GOVDELIVERY_PASSWORD=nottherealpassword rails s`

or export them using dotenv or similar.

## Available endpoints

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

# email-alert-api

Updates users that subscribe to specific GOV.UK email alerts.

Provides a consistent internal interface to external email notification services
(eg GovDelivery).

Given a tagged publication event it sends an email alert via GovDelivery for the
appropriate topic.

## Dependencies

* Postgres database (9.1 or higher - requires `hstore`)
* Redis (for [sidekiq](http://sidekiq.org/))
* GovDelivery API login and account (see
  [`gov_delivery.yml`](config/gov_delivery.yml) for required fields)

## Nomenclature

### Subscriber list

* An email subscriber list (actual email addresses on GovDelivery's servers)
* Associated tags indicate what the subscribers are interested in and what
  updates they should receive

### Topic

* GovDelivery terminology for a subscriber list
* Topics have tags
* Subscribers receive emails when you "send a bulletin" to that topic

### Bulletin

* GovDelivery terminology for an email notification

## Initial setup

* Check that the configuration in `config/database.yml` is right
* Run `bundle exec rake db:create && bundle exec db:schema:load` to load the
  database

## Running the test suite

Run `bundle exec rspec` to run the tests.

## Running the application

Run `./startup.sh`.

## GovDelivery interaction

GovDelivery client code is stored in `app/services/gov_delivery`.

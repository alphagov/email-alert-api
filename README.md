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

#### Troubleshooting

If you get this error when setting up the database:

```
ActiveRecord::StatementInvalid: PG::InsufficientPrivilege: ERROR:  permission denied to create extension "uuid-ossp"
HINT:  Must be superuser to create this extension.
: CREATE EXTENSION IF NOT EXISTS "uuid-ossp"
/var/govuk/email-alert-api/db/schema.rb:17:in `block in <main>'
/var/govuk/email-alert-api/db/schema.rb:13:in `<main>'
/usr/lib/rbenv/versions/2.6.1/bin/bundle:23:in `load'
/usr/lib/rbenv/versions/2.6.1/bin/bundle:23:in `<main>'
```

Try running `govuk_puppet` in the VM.

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

## Documentation

- [API Endpoints](doc/api.md)
- [Extracting analytics](doc/analytics.md)
- [Admin tasks available](doc/tasks.md)
- [Troubleshooting common problems](doc/troubleshooting.md)

## Licence

[MIT License](LICENCE)

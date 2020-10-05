# email-alert-api

Sends emails to users that subscribe to specific GOV.UK email alerts.

Provides a consistent internal interface to external email
notification services. Currently supports only [GOV.UK Notify](https://www.notifications.service.gov.uk/).

## Nomenclature

- **Content change**:
  * A publication event that creates or changes a content item
  * The representation of that event for the purpose of sending emails

- **Message**:
  * A message, distinct from a content change, that can be sent to subscribers of a list
  * The representation of that event for the purpose of sending emails

- **Subscriber list**:
  * A particular titled list that a user can sign up to
  * Contains criteria to determine which notifications a subscriber will receive (eg. all publications by HMRC)

- **Subscriber**:
  * A user who has subscribed to one or more subscriber lists

- **Subscription**:
  * The relationship between a subscriber and the subscription lists they are subscribed to

- **Digest run**:
  * One batch of either daily or weekly digests representing a particular subscription that has a start and end time and a set of subscribers to send emails to

- **Email**:
  * An email generated from content changes or messages to be sent to subscribers

- **Delivery attempt**:
  * An attempt to send a generated email to a subscriber using the external email notification services
  * Can be multiple attempts per email if there are errors

## Technical documentation

### Dependencies

* PostgreSQL database (9.3 or higher - requires `json` with `json_object_keys` method)
* Redis (for [Sidekiq](http://sidekiq.org/))
* GOV.UK Notify API key and other details (see
  [`email_service.yml`](config/email_service.yml) for required fields)

### Running the application

```bash
bundle exec rails server
```

### Running the test suite

```bash
bundle exec rspec
```

## Documentation

- [Analytics](docs/analytics.md)
- [API](docs/api.md)
- [Matching content to subscriber lists](docs/matching-content-to-subscriber-lists.md)
- [Support tasks](docs/support-tasks.md)
- [ENV vars](docs/env-vars.md)

## Licence

[MIT License](LICENCE)

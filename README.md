# email-alert-api

Sends emails to users that subscribe to specific GOV.UK email alerts

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

## Technical documentation

This is a Ruby on Rails app, and should follow [our Rails app conventions](https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html).

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

**Use GOV.UK Docker to run any commands that follow.**

### Running the test suite

```bash
bundle exec rake
```

### Further documentation

Check the [docs/](docs/) directory for detailed instructions, decisions and other documentation.

## Licence

[MIT License](LICENCE)

# Email Alert API

## Purpose
Updates users that subscribe to specific [GOV.UK](http://gov.uk) email alerts.

Maps GOV.UK tags to GovDelivery topics.

Given a tagged publication event it sends an email alert via GovDelivery for
the appropriate topic.

## Dependencies
* GovDelivery - A third party service for generating, subscribing to, and delivering emails.

## Nomenclature
* Subscriber list
  - An email subscriber list (actual email addresses on GovDelivery's servers)
  - Associated tags indicate what the subscribers are interested in and what updates they should receive
* Topic
  - GovDelivery terminology for a subscriber list
  - Topics have tags
  - Subscribers receive emails when you "send a bulletin" to that topic
* Bulletin
  - GovDelivery terminology for an email notification

## Initial setup
* Check that the database connection defaults in `config/env.rb` are
  appropriate.
* Create the databases: `bin/create_databases`

## Running the application
```
$ ./startup.sh
```

If you are using the GDS development virtual machine then the application will be available on the host at [http://email-alert-api.dev.gov.uk/](http://email-alert-api.dev.gov.uk/)

## Running the test suite
```
$ bundle exec rake
```

## Persistence
Postgresql database with [Sequel](http://sequel.jeremyevans.net/) library.

Migrations can be created using `bin/generate_migration <name_of_migration>`
and run using `bin/migrate`.

## Application Structure

### Entry point (/application.rb)
This object acts as the entry point to application and has a public method for
each client interaction the application offers, `#create_subscriber_list` and
`#notify_subscriber_lists_by_tags` for example.

These methods each take a service and compose it with several small aspect
objects, and then execute it. Each object in the chain does one thing, such as

* Filter bad input (filter aspect)
* Convert parameters into a domain object (mapping aspect)
* Build a new object (service)
* Persist a new or modified object (callback aspect)

#### Service objects
Provide the core functionality of an individual interaction.

#### Aspects
Wrap around the central service object and may modify one of

* The request parameters
* The responder object

`TagSetDomainAspect` accepts a `tag` parameter (a `Hash`) and converts that
data into a `TagSet` domain object. All downstream objects receive the domain
object and are protected from raw user input.

`SubscriberListPersistenceAspect` adds a callback to the responder so that it
can save the created subscriber list into the database whenever the downstream
service responds with a `created` message.

Aspects can optionally abort execution by sending a message to the responder instead of calling the next downstream object. This might be in order to reject
a request due to bad input (eg `ValidInputFilter` and `UniqueTagSetFilter`)

### HTTP boundary (/http/http_api.rb)
The Sinatra object acts as a router to map HTTP messages into application
messages. It should not contain any logic other than what is necessary to
trigger the interaction on the application object. Translation logic has been
extracted into a `SinatraAdapter` object that provides params and a responder.

The responder maps messages from the application `created`,
`missing_parameters` etc into HTTP response codes that Sinatra can communicate
back to the client.

This is known as the "delivery" boundary and could trivially be replaced by
something other than Sinatra such as another web framework, CLI, daemonized
process that talks to a queue. Support for new delivery mechanisms only
requires a new adapter to be written.

### Persistence boundary
The application has access to its persistence via a repository object that has
one method per query eg `all` and `find_by_tags`, and collaborates with a
datamapper to convert between datastore records and domain objects

The datastore adapter (`PostgresAdapter`) implements the datastore specific
code for the repository queries.

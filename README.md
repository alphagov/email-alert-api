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

If you are using the GDS development virtual machine then the application will be available on the host at [http://finder-frontend.dev.gov.uk/](http://finder-frontend.dev.gov.uk/)

## Running the test suite
```
$ bundle exec rake
```

## Persistence
Postgresql database with [Sequel](http://sequel.jeremyevans.net/) library.

Migrations can be created using `bin/generate_migration <name_of_migration>`
and run using `bin/migrate`.

## Application Structure
* Hexagonal Ruby application with service layer
* Sinatra as a web delivery plugin `/http`
* Repository pattern over a Postgres database

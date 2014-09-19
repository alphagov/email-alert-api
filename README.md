# Email Alert API

## Purpose
Updates users that subscribe to specific [GOV.UK](http://gov.uk) email alerts.

Maps GOV.UK tags to GovDelivery topics.

Given a tagged publication event it sends an email alert via GovDelivery for
the appropriate topic.

## Dependencies
* GovDelivery - A third party service for generating, subscribing to, and delivering emails.

## Nomenclature
Topic: A subscriber list to which we assign a unique set of tags.

## Running the application
```
$ ./startup.sh
```

If you are using the GDS development virtual machine then the application will be available on the host at [http://finder-frontend.dev.gov.uk/](http://finder-frontend.dev.gov.uk/)

## Running the test suite
```
$ bundle exec rake
```

## Application Structure
* Hexagonal Ruby application with service layer
* Sinatra as a web delivery plugin `/http`
* Repository pattern over a Postgres database

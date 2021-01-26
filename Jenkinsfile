#!/usr/bin/env groovy

library("govuk")

node("postgresql-9.6") {
  govuk.setEnvar("TEST_DATABASE_URL", "postgresql://email-alert-api:email-alert-api@localhost/email-alert-api_test")
  govuk.buildProject()
}

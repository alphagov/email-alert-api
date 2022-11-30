#!/usr/bin/env groovy

library("govuk")

node {
  govuk.setEnvar("TEST_DATABASE_URL", "postgresql://postgres@127.0.0.1:54313/email-alert-api-test")
  govuk.buildProject(
    overrideTestTask: { sh("bundle exec rake lint spec") }
  )
}

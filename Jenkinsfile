#!/usr/bin/env groovy

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'
  govuk.setEnvar("TEST_DATABASE_URL", "postgresql://email-alert-api:email-alert-api@localhost/email-alert-api_test")
  govuk.buildProject()
}

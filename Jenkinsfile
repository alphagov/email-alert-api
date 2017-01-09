#!/usr/bin/env groovy

REPOSITORY = 'email-alert-api'

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  properties([
    buildDiscarder(
      logRotator(
        numToKeepStr: '10')
      ),
    [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
    [$class: 'ThrottleJobProperty',
      categories: [],
      limitOneJobWithMatchingParams: true,
      maxConcurrentPerNode: 1,
      maxConcurrentTotal: 0,
      paramsToUseForLimit: REPOSITORY,
      throttleEnabled: true,
      throttleOption: 'category'],
  ])

  try {
    stage("Checkout") {
      checkout scm
    }

    stage("Clean up git") {
      govuk.cleanupGit()
    }

    stage("Configure Rails environment variable") {
      govuk.setEnvar("GOVUK_ENV", "test")
    }

    stage("bundle install") {
      govuk.bundleApp()
    }

    stage("Set up DB") {
      govuk.runRakeTask("db:drop db:create db:schema:load")
    }

    stage("Run tests") {
      sh("bundle exec rspec")
    }

    if (env.BRANCH_NAME == "master") {
      stage("Push release tag") {
        govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
      }

      stage("Deploy to Integration") {
        govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, 'release', 'deploy')
      }
    }
  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }
}

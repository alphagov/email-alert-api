Feature: Send a notification
  Notify subscribers of an update

  Scenario: Do the notification
    Given the subscriber list "CMA cases about markets and mergers" with tags
      """
      {
        "document_type": [ "cma_case" ],
        "case_type": [ "markets", "mergers" ]
      }
      """
    When I POST to "/notifications" with
      """
      {
        "subject": "Energy market investigation",
        "body": "The CMA is investigating the supply and acquisition of energy in Great Britain. https://www.gov.uk/cma-cases/energy-market-investigation",
        "tags": {
          "document_type": [ "cma_case" ],
          "case_type": [ "markets" ],
          "market_sector": [ "energy" ],
          "case_state": [ "open" ],
          "outcome": [ "markets-phase-1-referral" ],
          "organisation": [ "competition-markets-authority" ]
        }
      }
      """
    Then I get a "202" response with the following body
      """
        { }
      """
    And a notification is sent to the subscriber list

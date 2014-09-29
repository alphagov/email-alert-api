Feature: Create a topic
  Create a topic from a title and a set of tags

  Scenario: Creating a new topic
    Given there are no topics
    When I POST to "/topics" with
      """
      {
        "title": "CMA cases of type Markets and Mergers and about Energy",
        "tags": {
          "document_type": [ "cma_case" ],
          "case_type": [ "markets", "mergers" ],
          "market_sector": [ "energy" ]
        }
      }
      """
    Then I get a "201" response with the following body
      """
      {
        "topic": {
          "title": "CMA cases of type Markets and Mergers and about Energy",
          "subscription_url": "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=UKGOVUK_1234",
          "gov_delivery_id": "UKGOVUK_1234",
          "tags": {
            "document_type": [ "cma_case" ],
            "case_type": [ "markets", "mergers" ],
            "market_sector": [ "energy" ]
          }
        }
      }
      """
    And a topic is created

  Scenario: Topic already exists
    Given a topic already exists
    When I POST to "/topics" with duplicate tag set
    Then I get a "422" response with the following body
      """
        {
          "error": "A topic with that tag set already exists"
        }
      """
    And a topic has not been created

  Scenario: Unprocessable request
    Given there are no topics
    When I POST to "/topics" with
      """
      {
        "title": "Anything",
        "tags": {}
      }
      """
    Then I get a "422" response with the following body
      """
        {
          "error": "A topic was not created due to invalid attributes"
        }
      """
    When I POST to "/topics" with
      """
      {
        "title": "Anything",
        "tags": {
          "tag_key": "anything"
        }
      }
      """
    Then I get a "422" response with the following body
      """
        {
          "error": "A topic was not created due to invalid attributes"
        }
      """
    When I POST to "/topics" with
      """
      {
        "title": "Anything",
        "tags": ""
      }
      """
    Then I get a "422" response with the following body
      """
        {
          "error": "A topic was not created due to invalid attributes"
        }
      """
    When I POST to "/topics" with
      """
      {
        "title": "",
        "tags": {
          "document_type": [ "cma_case" ],
          "case_type": [ "markets", "mergers" ],
          "market_sector": [ "energy" ]
        }
      }
      """
    Then I get a "422" response with the following body
      """
        {
          "error": "A topic was not created due to invalid attributes"
        }
      """


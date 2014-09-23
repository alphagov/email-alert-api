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
    Then a topic is created
    And I get a "201" response with the following body
      """
      {
        "subscription_url": "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=ABC_1234"
      }
      """

  Scenario: Topic already exists
    Given a topic already exists
    When I POST to "/topics" with duplicate tag set
    Then I get a "422" response with the following body
      """
        {
          "error": "Topic with that tag set already exists"
        }
      """

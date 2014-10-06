Feature: Create a subscriber list
  Create a subscriber list from a title and a set of tags

  Scenario: Creating a new subscriber list
    Given there are no subscriber lists
    When I POST to "/subscriber_lists" with
      """
      {
        "title": "CMA cases of type Markets and Mergers and about Energy",
        "gov_delivery_id": "UKGOVUK_1234",
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
        "subscriber_list": {
          "id": "447135c3-07d6-4c3a-8a3b-efa49ef70e52",
          "title": "CMA cases of type Markets and Mergers and about Energy",
          "subscription_url": "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=UKGOVUK_1234",
          "gov_delivery_id": "UKGOVUK_1234",
          "created_at": "2014-10-06T14:00:00Z",
          "tags": {
            "document_type": [ "cma_case" ],
            "case_type": [ "markets", "mergers" ],
            "market_sector": [ "energy" ]
          }
        }
      }
      """
    And a subscriber list is created

  Scenario: Subscriber List already exists
    Given a subscriber list already exists
    When I POST to "/subscriber_lists" with duplicate tag set
    Then I get a "422" response with the following body
      """
        {
          "error": "A subscriber list with that tag set already exists"
        }
      """
    And a subscriber list has not been created

  Scenario: Create list with duplicate tags with different ordering
    Given a subscriber list already exists
    When I POST to "/subscriber_lists" with duplicate but differently ordered tag set
    Then I get a "422" response with the following body
      """
        {
          "error": "A subscriber list with that tag set already exists"
        }
      """
    And a subscriber list has not been created

  Scenario: Invalid parameters
    When I POST to "/subscriber_lists" with invalid parameters
    Then I get a "422" response with the following body
      """
        {
          "error": "Request rejected due to invalid parameters"
        }
      """

Feature: Get a subscriber list
  Search for a subscriber list by tags

  Scenario: Search for an existing subscriber list
    Given the subscriber list "CMA cases about markets and mergers" with tags
      """
      {
        "document_type": [ "cma_case" ],
        "case_type": [ "markets", "mergers" ]
      }
      """
    When I GET "/subscriber_lists" with query
      """
      {
        "tags": {
          "document_type": [ "cma_case" ],
          "case_type": [ "markets", "mergers" ]
        }
      }
      """
    Then I get a "200" response with the following body
      """
      {
        "subscriber_list": {
          "id": "447135c3-07d6-4c3a-8a3b-efa49ef70e52",
          "title": "CMA cases about markets and mergers",
          "subscription_url": "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=UKGOVUK_1234",
          "gov_delivery_id": "UKGOVUK_1234",
          "tags": {
            "document_type": [ "cma_case" ],
            "case_type": [ "markets", "mergers" ]
          }
        }
      }
      """

  Scenario: Subscriber list does not exist
    Given the subscriber list does not already exist
    When I GET "/subscriber_lists" with query
      """
      {
        "tags": {
          "document_type": [ "cma_case" ],
          "case_type": [ "markets", "mergers" ]
        }
      }
      """
    Then I get a "404" response with the following body
      """
      {
        "error": "A subscriber list with those tags does not exist"
      }
      """

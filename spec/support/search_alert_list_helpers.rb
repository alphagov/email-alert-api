module SearchAlertListHelpers
  def medical_safety_alert_search_body(content_id:, public_timestamp:)
    {
      results: [
        {
          content_id:,
          link: "/drug-device-alerts/test",
          public_timestamp:,
          index: "govuk",
          es_score: nil,
          model_score: nil,
          original_rank: nil,
          combined_score: nil,
          _id: "/drug-device-alerts/test",
          elasticsearch_type: "medical_safety_alert",
          document_type: "medical_safety_alert",
        },
      ],
      total: 1,
      start: 0,
      aggregates: {},
      suggested_queries: [],
      suggested_autocomplete: [],
      es_cluster: "A",
      reranked: false,
    }
  end

  def stub_medical_safety_alert_feed(content_id:, age:)
    stub_request(:get, "http://search-api.dev.gov.uk/search.json?count=50&fields=content_id,link,public_timestamp&filter_format=medical_safety_alert&order=-public_timestamp")
      .to_return(status: 200, body: medical_safety_alert_search_body(content_id:, public_timestamp: (Time.zone.now - age).strftime("%Y-%m-%dT%H:%M:%SZ")).to_json, headers: {})
  end
end

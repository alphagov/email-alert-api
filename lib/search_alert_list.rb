module SearchAlertList
  MIN_AGE = 1.hour
  MAX_AGE = 2.days
  MAX_RESULTS = 50

  def get_alert_content_items(document_type:)
    results = GdsApi.search.search(count: MAX_RESULTS, fields: "content_id,link,public_timestamp", filter_format: document_type, order: "-public_timestamp")

    output = results["results"].map do |result|
      publish_time = Time.zone.parse(result["public_timestamp"])
      if publish_time.between?(Time.zone.now - MAX_AGE, Time.zone.now - MIN_AGE)
        { content_id: result["content_id"], valid_from: publish_time, url: result["link"] }
      end
    end

    output.compact
  end
end

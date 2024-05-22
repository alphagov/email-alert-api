module PublicUrls
  class << self
    def url_for(base_path:, **params)
      uri = URI.join(website_root, base_path)
      query = Hash[URI.decode_www_form(uri.query.to_s)]

      query = query.merge(default_utm_params) if params.key?(:utm_source)
      query = query.merge(params).compact

      uri.query = URI.encode_www_form(query).presence
      uri.to_s
    end

    def manage_url(subscriber, **utm_params)
      params = utm_params.merge(address: subscriber.address)
      url_for(base_path: "/email/manage/authenticate", **params)
    end

    def unsubscribe(subscription, **utm_params)
      subscriber_id = subscription.subscriber_id
      token = AuthTokenGeneratorService.call(subscriber_id:)

      params = utm_params.merge(token:)
      url_for(base_path: "/email/unsubscribe/#{subscription.id}", **params)
    end

    def unsubscribe_one_click(subscription, **utm_params)
      subscriber_id = subscription.subscriber_id
      token = AuthTokenGeneratorService.call(subscriber_id:, one_click: true)

      params = utm_params.merge(token:)
      url_for(base_path: "/email/unsubscribe/one-click/#{subscription.id}", **params)
    end

  private

    def website_root
      Plek.new.website_root
    end

    def default_utm_params
      { utm_medium: "email", utm_campaign: "govuk-notifications" }
    end
  end
end

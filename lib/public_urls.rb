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

    def authenticate_url(address:)
      url_for(base_path: "/email/manage/authenticate", address: address)
    end

    def unsubscribe(subscription_id:, subscriber_id:)
      token = AuthTokenGeneratorService.call(subscriber_id: subscriber_id)
      url_for(base_path: "/email/unsubscribe/#{subscription_id}", token: token)
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

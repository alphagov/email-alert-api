module PublicUrls
  class << self
    def url_for(base_path:)
      URI.join(website_root, base_path).to_s
    end

    def authenticate_url(address:)
      "#{website_root}/email/manage/authenticate?#{param('address', address)}"
    end

    def unsubscribe(subscription_id:, subscriber_id:)
      token = AuthTokenGeneratorService.call(subscriber_id: subscriber_id)
      "#{website_root}/email/unsubscribe/#{subscription_id}?token=#{token}"
    end

  private

    def website_root
      Plek.new.website_root
    end

    def param(key, value)
      "#{key}=#{ERB::Util.url_encode(value)}"
    end
  end
end

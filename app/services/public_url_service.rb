module PublicUrlService
  class << self
    def content_url(base_path:)
      "#{website_root}#{base_path}"
    end

    def deprecated_subscription_url(gov_delivery_id:)
      config = EmailAlertAPI.config.gov_delivery

      proto = config.fetch(:protocol)
      host = config.fetch(:public_hostname)
      code = config.fetch(:account_code)
      params = param(:topic_id, gov_delivery_id)

      "#{proto}://#{host}/accounts/#{code}/subscriber/new?#{params}"
    end

    def unsubscribe_url(uuid:, title:)
      "#{website_root}/email/unsubscribe/#{uuid}?#{param(:title, title)}"
    end

  private

    def website_root
      Plek.new.website_root
    end

    def param(key, value)
      "#{key}=#{URI.encode(value, /\W/)}"
    end
  end
end

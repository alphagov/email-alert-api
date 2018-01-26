module PublicUrlService
  class << self
    def content_url(base_path:)
      URI.join(website_root, base_path).to_s
    end

    alias_method :url_for, :content_url

    # This url is for the page mid-way through the signup journey where the user
    # enters their email address. At present, multiple frontends start the
    # journey, e.g. collections, but eventually all these will be consolidated
    # into email-alert-frontend and this URL will no longer be needed.
    def subscription_url(gov_delivery_id:)
      params = param(:topic_id, gov_delivery_id)
      "#{website_root}/email/subscriptions/new?#{params}"
    end

    # This url is for the page mid-way through the signup journey where the user
    # enters their email address. This is where we handover to govdelivery.
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
      "#{key}=#{ERB::Util.url_encode(value)}"
    end
  end
end

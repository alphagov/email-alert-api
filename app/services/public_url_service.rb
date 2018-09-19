module PublicUrlService
  class << self
    def url_for(base_path:)
      URI.join(website_root, base_path).to_s
    end

    # This url is for the page mid-way through the signup journey where the user
    # enters their email address. At present, multiple frontends start the
    # journey, e.g. collections, but eventually all these will be consolidated
    # into email-alert-frontend and this URL will no longer be needed.
    def subscription_url(slug:)
      params = param(:topic_id, slug)
      "#{website_root}/email/subscriptions/new?#{params}"
    end

    def authenticate_url(address:)
      "#{website_root}/email/authenticate?#{param('address', address)}"
    end

    def absolute_url(path:)
      File.join(website_root, path)
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

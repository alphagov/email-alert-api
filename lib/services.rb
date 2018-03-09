module Services
  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(Plek.new.find("content-store"))
  end

  def self.rate_limiter
    @rate_limiter ||= Ratelimit.new("deliveries")
  end
end

module Services
  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(Plek.new.find("content-store"))
  end

  def self.rate_limiter
    @rate_limiter ||= Ratelimit.new("deliveries")
  end

  def self.business_readiness
    @business_readiness ||= begin
      path = File.join(Rails.root, "config", "business_readiness.csv")
      base_paths_with_tags = BusinessReadiness::Loader.new(path).base_paths_with_tags
      BusinessReadiness::ContentChangeInjector.new(base_paths_with_tags)
    end
  end
end

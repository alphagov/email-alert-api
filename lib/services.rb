module Services
  def self.rate_limiter
    @rate_limiter ||= Ratelimit.new("email-alert-api:deliveries")
  end
end

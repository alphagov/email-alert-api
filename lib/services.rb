module Services
  def self.rate_limiter
    @rate_limiter ||= Ratelimit.new("email-alert-api:deliveries")
  end

  def self.accounts_emails
    @accounts_emails ||=
      File.readlines(Rails.root.join("config/bulk_email/email_addresses.txt"), chomp: true)
  end
end

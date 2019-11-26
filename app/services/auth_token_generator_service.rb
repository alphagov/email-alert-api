class AuthTokenGeneratorService
  def self.call(*args)
    new.call(*args)
  end

  def call(data, expiry: 1.week.from_now)
    token_data = {
      "data" => data,
      "exp" => expiry.to_i,
      "iat" => Time.now.to_i,
      "iss" => "https://www.gov.uk",
    }
    JWT.encode(token_data, secret, "HS256")
  end

  private_class_method :new

private

  def secret
    Rails.application.secrets.email_alert_auth_token
  end
end

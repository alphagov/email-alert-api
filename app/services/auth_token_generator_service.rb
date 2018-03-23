class AuthTokenGeneratorService
  def self.call(*args)
    new.call(*args)
  end

  def call(subscriber, redirect: nil, expiry: 1.week.from_now)
    data = token_data(subscriber, redirect, expiry)
    JWT.encode(data, secret, "HS256")
  end

  private_class_method :new

private

  def token_data(subscriber, redirect, expiry)
    {
      "data" => {
        "subscriber_id" => subscriber.id,
        "redirect" => redirect,
      },
      "exp" => expiry.to_i,
      "iat" => Time.now.to_i,
      "iss" => "https://www.gov.uk",
    }
  end

  def secret
    Rails.application.secrets.email_alert_auth_token
  end
end

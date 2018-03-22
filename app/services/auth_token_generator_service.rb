class AuthTokenGeneratorService
  def self.call(subscriber)
    new.call(subscriber)
  end

  def call(subscriber)
    data = { "data" => { "subscriber_id" => subscriber.id } }
    JWT.encode(data, secret, "HS256")
  end

  private_class_method :new

private

  def secret
    Rails.application.secrets.email_alert_auth_token
  end
end

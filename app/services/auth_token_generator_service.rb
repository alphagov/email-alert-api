class AuthTokenGeneratorService
  CIPHER = "aes-256-gcm".freeze
  OPTIONS = { cipher: CIPHER, serializer: JSON }.freeze

  def self.call(*args)
    new.call(*args)
  end

  def call(data, expiry: 1.week)
    len = ActiveSupport::MessageEncryptor.key_len(CIPHER)
    key = ActiveSupport::KeyGenerator.new(secret).generate_key("", len)
    crypt = ActiveSupport::MessageEncryptor.new(key, OPTIONS)
    token = crypt.encrypt_and_sign(data, expires_in: expiry)
    CGI.escape(token)
  end

  private_class_method :new

private

  def secret
    Rails.application.secrets.email_alert_auth_token
  end
end

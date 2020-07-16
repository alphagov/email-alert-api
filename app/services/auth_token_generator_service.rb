class AuthTokenGeneratorService < ApplicationService
  CIPHER = "aes-256-gcm".freeze
  OPTIONS = { cipher: CIPHER, serializer: JSON }.freeze

  attr_reader :data, :expiry

  def initialize(data, expiry: 1.week)
    @data = data
    @expiry = expiry
  end

  def call
    len = ActiveSupport::MessageEncryptor.key_len(CIPHER)
    key = ActiveSupport::KeyGenerator.new(secret).generate_key("", len)
    crypt = ActiveSupport::MessageEncryptor.new(key, OPTIONS)
    token = crypt.encrypt_and_sign(data, expires_in: expiry)
    CGI.escape(token)
  end

private

  def secret
    Rails.application.secrets.email_alert_auth_token
  end
end

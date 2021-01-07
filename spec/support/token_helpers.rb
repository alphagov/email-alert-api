module TokenHelpers
  def decrypt_and_verify_token(data)
    cipher = AuthTokenGeneratorService::CIPHER
    len = ActiveSupport::MessageEncryptor.key_len(cipher)

    secret = Rails.application.secrets.email_alert_auth_token
    key = ActiveSupport::KeyGenerator.new(secret).generate_key("", len)

    options = AuthTokenGeneratorService::OPTIONS
    crypt = ActiveSupport::MessageEncryptor.new(key, **options)
    crypt.decrypt_and_verify(data)
  end
end

module TokenHelpers
  def decrypt_token_from_link(body)
    token = URI.decode_www_form_component(
      body.match(/token=([^&)]+)/)[1],
    )

    decrypt_and_verify_token(token)
  end

  def decrypt_and_verify_token(data)
    cipher = AuthTokenGeneratorService::CIPHER
    len = ActiveSupport::MessageEncryptor.key_len(cipher)

    secret = Rails.application.credentials.email_alert_auth_token
    key = ActiveSupport::KeyGenerator.new(secret, hash_digest_class: OpenSSL::Digest::SHA256).generate_key("", len)

    options = AuthTokenGeneratorService::OPTIONS
    crypt = ActiveSupport::MessageEncryptor.new(key, **options)
    crypt.decrypt_and_verify(data)
  end
end

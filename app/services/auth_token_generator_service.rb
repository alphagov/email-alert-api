class AuthTokenGeneratorService
  include Callable

  CIPHER = "aes-256-gcm".freeze
  OPTIONS = { cipher: CIPHER, serializer: JSON }.freeze

  attr_reader :data, :expiry

  def initialize(data, expiry: 1.week)
    @data = data
    @expiry = expiry
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    self.class.crypt.encrypt_and_sign(data, expires_in: expiry)
  end

  def self.crypt
    @crypt ||= begin
      secret = Rails.application.credentials.email_alert_auth_token
      len = ActiveSupport::MessageEncryptor.key_len(CIPHER)
      key = ActiveSupport::KeyGenerator.new(secret).generate_key("", len)
      ActiveSupport::MessageEncryptor.new(key, **OPTIONS)
    end
  end
end

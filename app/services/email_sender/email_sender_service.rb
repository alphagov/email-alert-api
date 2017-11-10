class EmailSenderService
  class ClientError < StandardError
    def initialize(status, original_exception)
      @status = status
      @original_exception = original_exception
    end

    attr_reader :status, :original_exception
  end

  def initialize(config, email_service_provider)
    @email_address_override = config[:email_address_override]
    @provider = email_service_provider
  end

  def call(address:, subject:, body:)
    log_override(address: address, subject: subject, body: body) if email_address_override

    provider.call(
      address: email_address_override || address,
      subject: subject,
      body: body
    )
  rescue ClientError => ex
    raise ex.original_exception unless ex.status == :technical_failure
  end

private

  attr_reader :provider, :email_address_override

  def log_override(address:, subject:, body:)
    overriden = " (overriden to #{email_address_override}) "
    logger.info(%(Sending email to #{address}#{overriden}
Subject: #{subject}
Body: #{body}
))
  end

  def logger
    Rails.logger
  end
end

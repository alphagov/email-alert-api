class SendEmailService::SendPseudoEmail
  def initialize(email)
    @email = email
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Rails.logger.info <<~INFO
      Logging email (#{email.id}) we'd have attempted to send to #{email.address}
      Subject: #{email.subject}
    INFO

    Metrics.sent_to_pseudo_successfully
    email.update!(status: :sent, sent_at: Time.zone.now)
  end

private

  attr_reader :email
end

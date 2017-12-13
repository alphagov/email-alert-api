class PseudoProvider
  LOG_PATH = "#{Rails.root}/log/pseudo_email.log".freeze

  attr_accessor :logger

  def self.call(*args)
    new.call(*args)
  end

  def initialize
    self.logger = Logger.new(LOG_PATH, 5, 4194304)
  end

  def call(address:, subject:, body:, reference:)
    logger.info(<<-INFO.strip_heredoc)
      Sending email to #{address}
      Subject: #{subject}
      Body: #{body}
      Reference: #{reference}
    INFO

    MetricsService.sent_to_pseudo_successfully
  end
end

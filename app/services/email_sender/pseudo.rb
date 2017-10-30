module EmailSender
  class Pseudo
    def call(address:, subject:, body:)
      logger.info(%(Sending email to #{address}
Subject: #{subject}
Body: #{body}
))
    end

  private

    def logger
      @logger ||= Logger.new("#{Rails.root}/log/pseudo_email.log")
    end
  end
end


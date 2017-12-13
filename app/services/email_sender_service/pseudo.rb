class EmailSenderService
  class Pseudo
    def call(address:, subject:, body:)
      logger.info(%(Sending email to #{address}
Subject: #{subject}
Body: #{body}
))
      GovukStatsd.increment("pseudo.email_send_request.success")

      "" # provider reference
    end

  private

    def logger
      @logger ||= Logger.new("#{Rails.root}/log/pseudo_email.log", 5, 4194304)
    end
  end
end

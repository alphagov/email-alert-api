module Reports
  class ContentChangeEmailFailures
    def initialize(content_change)
      @content_change = content_change
      @failed_emails = failed_emails
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      puts <<~HEADING
        #{@failed_emails.count} Email failures for Content Change #{@content_change.id}
        -------------------------------------------

      HEADING

      @failed_emails.each do |email|
        puts <<~EMAIL
          Email Id:       #{email.id}
          Failure Reason: #{email.failure_reason}

          -------------------------------------------

        EMAIL
      end
    end

  private

    def failed_emails
      subscription_contents_ids = @content_change
                                  .subscription_contents
                                  .pluck(:id)
      email_ids = SubscriptionContent
                  .where(id: subscription_contents_ids)
                  .pluck(:email_id)
      Email.where(id: email_ids, status: "failed")
    end
  end
end

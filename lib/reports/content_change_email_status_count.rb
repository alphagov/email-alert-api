module Reports
  class ContentChangeEmailStatusCount
    def initialize(content_change)
      @content_change = content_change
      @email_status_count = email_status_count
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      puts <<~TEXT
        -------------------------------------------
        Email status counts for Content Change #{@content_change.id}
        -------------------------------------------

        Sent emails: #{@email_status_count['sent']}

        Pending emails: #{@email_status_count['pending']}

        Failed emails: #{@email_status_count['failed']}

        -------------------------------------------
      TEXT
    end

  private

    def email_status_count
      subscription_contents_ids = @content_change.subscription_contents.pluck(:id)
      email_ids = SubscriptionContent.where(id: subscription_contents_ids).pluck(:email_id)
      Email.where(id: email_ids).group(:status).count
    end
  end
end

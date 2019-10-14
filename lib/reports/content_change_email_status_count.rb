module Reports
  class ContentChangeEmailStatusCount
    def initialize(content_changes)
      @content_changes = content_changes
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      @content_changes.each do |content_change|
        email_status_count_for_content_change = email_status_count(content_change)

        puts <<~TEXT

          ---------------------------------------------------------------------------
          Email status counts for Content Change #{content_change.id}
          ---------------------------------------------------------------------------
          Sent emails: #{email_status_count_for_content_change['sent']}
          Pending emails: #{email_status_count_for_content_change['pending']}
          Failed emails: #{email_status_count_for_content_change['failed']}
          ---------------------------------------------------------------------------
        TEXT
      end
    end

  private

    def email_status_count(content_change)
      email_ids = content_change.subscription_contents.select(:email_id)
      Email.where(id: email_ids).group(:status).count
    end
  end
end

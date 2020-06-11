module Reports
  class ContentChangeEmailFailures
    def initialize(ids:)
      @content_changes = ContentChange.where(id: ids)
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      @content_changes.each do |content_change|
        failed_emails = failed_emails(content_change)

        puts <<~HEADING

          ------------------------------------------------------------------------
          #{failed_emails.count} Email failures for Content Change #{content_change.id}
          ------------------------------------------------------------------------
        HEADING

        failed_emails.each do |email|
          puts <<~EMAIL

            Email Id:       #{email[0]}
            Failure Reason: #{email[1]}
            ------------------------------------------------------------------------
          EMAIL
        end
      end
    end

  private

    def failed_emails(content_change)
      email_ids = content_change.subscription_contents.select(:email_id)
      Email.where(id: email_ids, status: "failed").sort_by(&:created_at).pluck(:id, :failure_reason)
    end
  end
end

module ImmediateDelivery
  class QueueUnsentEmailsForContentChange
    def initialize(content_change_id:)
      @content_change_id = content_change_id
    end

    def self.call(content_change_id:)
      new(content_change_id: content_change_id).execute
    end

    def execute
      resend
    end

  private

    attr_accessor :content_change_id

    def resend
      SubscriptionContentsAndUnsentEmailForContentChange.call(content_change_id).each do |subscription_content|
        DeliveryRequestWorker.perform_async_in_queue(subscription_content.email.id, queue: :delivery_immediate_high)
      end
    end
  end
end

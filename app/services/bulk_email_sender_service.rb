class BulkEmailSenderService
  def self.call(subject:, body:, subscriber_lists:, queue: :delivery_immediate)
    email_ids = BulkEmailBuilder.call(subject: subject, body: body, subscriber_lists: subscriber_lists).ids

    email_ids.each do |email_id|
      DeliveryRequestWorker.perform_async(email_id, queue)
    end
  end
end

class BulkEmailSenderService
  def self.call(bulk_email_builder:, queue: :delivery_immediate)
    email_ids = bulk_email_builder.ids

    email_ids.each do |email_id|
      DeliveryRequestWorker.perform_async(email_id, queue)
    end
  end
end

class MetricsService
  class << self
    def sent_to_notify_successfully
      increment("notify.email_send_request.success")
    end

    def failed_to_send_to_notify
      increment("notify.email_send_request.failure")
    end

    def sent_to_pseudo_successfully
      increment("pseudo.email_send_request")
    end

    def content_change_created
      increment("content_changes_created")
    end

    def govdelivery_topic_response(status)
      increment("responses.#{status}")
    end

    def email_send_request(provider_name, &block)
      time("#{provider_name}.email_send_request.timing", &block)
    end

    def digest_email_generation(range, &block)
      time("digest_email_generation.#{range}.timing", &block)
    end

    def digest_initiator_service(range, &block)
      time("digest_initiator_service.#{range}.timing", &block)
    end

    def first_delivery_attempt(email, time)
      return if DeliveryAttempt.exists?(email: email)
      store_time_to_send_email(email, time)
      store_time_to_send_content_change(email, time)
    end

    def store_time_to_send_email(email, time)
      difference = (time - email.created_at) * 1000
      namespace = "email_created_to_first_delivery_attempt"
      timing(namespace, difference)
    end

    def store_time_to_send_content_change(email, time)
      return if SubscriptionContent.where(email: email).digest.exists?

      content_change = ContentChangesForEmailQuery.call(email).first
      return unless content_change

      difference = (time - content_change.created_at) * 1000
      namespace = "content_change_created_to_first_delivery_attempt"
      timing(namespace, difference)
    end

  private

    def increment(metric)
      GovukStatsd.increment(metric)
    end

    def time(metric, &block)
      GovukStatsd.time(metric, &block)
    end

    def timing(namespace, difference)
      GovukStatsd.timing(namespace, difference)
    end
  end
end

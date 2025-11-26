class Metrics
  class << self
    def content_change_emails(content_change, count)
      count("content_change_emails.publishing_app.#{content_change.publishing_app}.immediate", count)
      count("content_change_emails.document_type.#{content_change.document_type}.immediate", count)
    end

    def unsubscribed(reason, value = 1)
      PrometheusMetrics.observe("unsubscribed_reason", value, { reason: reason })
    end

    def sent_to_notify_successfully
      PrometheusMetrics.observe("notify_email_send_request_success", 1)
    end

    def failed_to_send_to_notify
      increment("notify.email_send_request.failure")
    end

    def sent_to_pseudo_successfully
      increment("pseudo.email_send_request")
    end

    def content_change_created
      PrometheusMetrics.observe("content_changes_created", 1)
    end

    def message_created
      increment("messages_created")
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

    def email_bulk_insert(size, &block)
      time("email_bulk_insert.#{size}.timing", &block)
    end

    def content_change_created_until_email_sent(created_time, sent_time)
      difference = (sent_time - created_time) * 1000
      timing("content_change_created_until_email_sent", difference)
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

    def count(namespace, value)
      GovukStatsd.count(namespace, value)
    end
  end
end

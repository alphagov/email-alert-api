class Metrics
  class << self
    def content_change_emails(content_change, count)
      PrometheusMetrics.observe("immediate_content_change_batch_emails", count, { publishing_app: content_change.publishing_app, document_type: content_change.document_type })
    end

    def unsubscribed(reason, value = 1)
      PrometheusMetrics.observe("unsubscribed_reason", value, { reason: reason })
    end

    def sent_to_notify_successfully
      PrometheusMetrics.observe("notify_email_send_request_success", 1)
    end

    def failed_to_send_to_notify
      PrometheusMetrics.observe("notify_email_send_request_failure", 1)
    end

    def sent_to_pseudo_successfully
      PrometheusMetrics.observe("pseudo_email_send_request_success", 1)
    end

    def content_change_created
      PrometheusMetrics.observe("content_changes_created", 1)
    end

    def message_created
      PrometheusMetrics.observe("message_created", 1)
    end

    def email_send_request(provider_name)
      PrometheusMetrics.observe("email_send_request", 1, { provider: provider_name })
    end

    def digest_email_generation(range)
      PrometheusMetrics.observe("digest_email_generation", 1, { range: range })
    end

    def digest_initiator_service(range)
      PrometheusMetrics.observe("digest_initiator_service", 1, { range: range })
    end

    def email_bulk_insert(size, &block)
      time("email_bulk_insert.#{size}.timing", &block)
    end

    def content_change_created_until_email_sent(created_time, sent_time)
      difference = (sent_time - created_time) * 1000

      PrometheusMetrics.observe("content_change_created_until_email_sent", difference)
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

class PrometheusMetrics
  PREFIX = "email_alert_api_".freeze

  GAUGES = [
    {
      name: "total_unprocessed_content_changes",
      description: "Total number of unprocessed content changes over 120 minutes old.",
    },
    {
      name: "total_unprocessed_digest_runs",
      description: "Total number of unprocessed digest runs over 120 minutes old.",
    },
    {
      name: "total_unprocessed_messages",
      description: "Total number of unprocessed messages over 120 minutes old.",
    },
    {
      name: "immediate_content_change_batch_emails",
      description: "Total number of batched content change emails by publishing app and document type",
    },
    {
      name: "content_change_created_until_email_sent",
      description: "Time between content change created and email sent (milliseconds)",
    },
  ].freeze

  COUNTERS = [
    {
      name: "content_changes_created",
      description: "Content changes counter",
    },
    {
      name: "unsubscribed_reason",
      description: "Counter for user unsubscribed and reason",
    },
    {
      name: "notify_email_send_request_success",
      description: "Counter for successful email send requests to Notify",
    },
    {
      name: "notify_email_send_request_failure",
      description: "Counter for failed email send requests to Notify",
    },
    {
      name: "pseudo_email_send_request_success",
      description: "Counter for successful pseudo email send request",
    },
    {
      name: "message_created",
      description: "Counter for messages created",
    },
    {
      name: "email_send_request",
      description: "Counter for when email send request has been made to Notify/pseudo",
    },
    {
      name: "digest_email_generation",
      description: "Counter for when a digest email has been generated",
    },
  ].freeze

  def self.register
    GAUGES.each do |gauge|
      PrometheusExporter::Client.default.register(
        :gauge, name_with_prefix(gauge[:name]), gauge[:description]
      )
    end

    COUNTERS.each do |counter|
      PrometheusExporter::Client.default.register(
        :counter, name_with_prefix(counter[:name]), counter[:description]
      )
    end
  end

  def self.observe(name, value, labels = {})
    metric = PrometheusExporter::Client.default.find_registered_metric(name_with_prefix(name))
    metric.observe(value, labels)
  end

  def self.name_with_prefix(name)
    "#{PREFIX}#{name}"
  end
end

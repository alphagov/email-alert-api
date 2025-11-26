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

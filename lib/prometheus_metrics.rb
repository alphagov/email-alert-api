class PrometheusMetrics
  PREFIX = "email_alert_api_".freeze

  GAUGES = [
    {
      name: "total_unprocessed_content_changes",
      description: "Total number of unprocessed content changes over 120 minutes old.",
    },
  ].freeze

  def self.register
    GAUGES.each do |gauge|
      PrometheusExporter::Client.default.register(
        :gauge, name_with_prefix(gauge[:name]), gauge[:description]
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

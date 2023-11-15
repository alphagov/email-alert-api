require "prometheus_exporter"
require "prometheus_exporter/server"

module Collectors
  class GlobalPrometheusCollector < PrometheusExporter::Server::TypeCollector
    def type
      "email_alert_api_global"
    end

    def metrics
      current_medical_safety_alerts = PrometheusExporter::Metric::Gauge.new("email_alert_api_current_medical_safety_alerts", "Number of medical safety alerts email-alert-api is checking")
      current_medical_safety_alerts.observe(Rails.cache.fetch("current_medical_safety_alerts") { 0 })
      delivered_medical_safety_alerts = PrometheusExporter::Metric::Gauge.new("email_alert_api_delivered_medical_safety_alerts", "Number of current medical safety alerts marked as delivered")
      delivered_medical_safety_alerts.observe(Rails.cache.fetch("delivered_medical_safety_alerts") { 0 })
      current_travel_advice_alerts = PrometheusExporter::Metric::Gauge.new("email_alert_api_current_travel_advice_alerts", "Number of travel advice alerts email-alert-api is checking")
      current_travel_advice_alerts.observe(Rails.cache.fetch("current_travel_advice_alerts") { 0 })
      delivered_travel_advice_alerts = PrometheusExporter::Metric::Gauge.new("email_alert_api_delivered_travel_advice_alerts", "Number of current travel advice alerts marked as delivered")
      delivered_travel_advice_alerts.observe(Rails.cache.fetch("delivered_travel_advice_alerts") { 0 })

      [current_medical_safety_alerts, delivered_medical_safety_alerts, current_travel_advice_alerts, delivered_travel_advice_alerts]
    end
  end
end

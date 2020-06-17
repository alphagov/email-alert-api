class Metrics::MessageExporter < Metrics::BaseExporter
  def call
    GlobalMetricsService.critical_messages_total(critical_messages)
    GlobalMetricsService.warning_messages_total(warning_messages)
  end

private

  def critical_messages
    @critical_messages ||= count_messages(critical_latency)
  end

  def warning_messages
    @warning_messages ||= count_messages(warning_latency)
  end

  def count_messages(age)
    Message
    .where("created_at < ?", age.ago)
    .where(processed_at: nil)
    .count
  end

  def critical_latency
    10.minutes
  end

  def warning_latency
    5.minutes
  end
end

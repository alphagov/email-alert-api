class Metrics::MessageExporter < Metrics::BaseExporter
  def call
    GovukStatsd.gauge("messages.critical_total", critical_messages)
    GovukStatsd.gauge("messages.warning_total", warning_messages)
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
    120.minutes
  end

  def warning_latency
    90.minutes
  end
end

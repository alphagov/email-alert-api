class Metrics::ContentChangeExporter < Metrics::BaseExporter
  def call
    GovukStatsd.gauge("content_changes.critical_total", critical_content_changes)
    GovukStatsd.gauge("content_changes.warning_total", warning_content_changes)
  end

private

  def critical_content_changes
    @critical_content_changes ||= count_content_changes(critical_latency)
  end

  def warning_content_changes
    @warning_content_changes ||= count_content_changes(warning_latency)
  end

  def count_content_changes(age)
    ContentChange
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

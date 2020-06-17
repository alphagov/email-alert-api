class Metrics::StatusUpdateExporter < Metrics::BaseExporter
  def call
    GovukStatsd.gauge("delivery_attempt.pending_status_total", total_pending)
    GovukStatsd.gauge("delivery_attempt.total", total)
  end

private

  def totals
    @totals ||= DeliveryAttempt
      .where("created_at > ? AND created_at <= ?", (1.hour + 10.minutes).ago, 10.minutes.ago)
      .group("CASE WHEN status = 0 THEN 'pending' ELSE 'done' END")
      .count
  end

  def total_pending
    totals.fetch("pending", 0)
  end

  def total_done
    totals.fetch("done", 0)
  end

  def total
    total_pending + total_done
  end
end

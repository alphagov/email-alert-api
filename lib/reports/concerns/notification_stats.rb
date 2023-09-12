module Reports::Concerns::NotificationStats
  def list_names_array(lists)
    lists.map { |l| "#{l.title} (#{l.subscriptions.active.count} active subscribers)" }
  end

  def list_stats_array(lists)
    total_subs = lists.sum { |l| l.subscriptions.active.count }
    immediately_subs = lists.sum { |l| l.subscriptions.active.immediately.count }
    daily_subs = lists.sum { |l| l.subscriptions.active.daily.count }
    weekly_subs = lists.sum { |l| l.subscriptions.active.weekly.count }

    [
      "notified immediately: #{immediately_subs}",
      "notified next day:    #{daily_subs}",
      "notified at weekend:  #{weekly_subs}",
      "notified total:       #{total_subs}",
    ]
  end
end

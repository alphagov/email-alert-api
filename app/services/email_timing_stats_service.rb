class EmailTimingStatsService
  def self.first_delivery_attempt(email, time)
    return if DeliveryAttempt.exists?(email: email)
    store_time_to_send_email(email, time)
    store_time_to_send_content_change(email, time)
  end

  def self.store_time_to_send_email(email, time)
    difference = (time - email.created_at) * 1000
    namespace = "#{Socket.gethostname}.email_created_to_first_delivery_attempt"
    EmailAlertAPI.statsd.timing(namespace, difference)
  end

  def self.store_time_to_send_content_change(email, time)
    # We don't want to store this statistic for emails that have more than one
    # content change associated with them. Since they don't exist yet this
    # does just a crude check.
    content_changes = ContentChangesForEmailQuery.call(email).all
    return unless content_changes.count == 1

    content_change = content_changes.first
    difference = (time - content_change.created_at) * 1000
    namespace = "#{Socket.gethostname}.content_change_created_to_first_delivery_attempt"
    EmailAlertAPI.statsd.timing(namespace, difference)
  end
end

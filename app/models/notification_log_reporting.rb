# NOTE: This we need to be updated once a disabled flag is added as it will
# affect the reporting logic.
class NotificationLogReporting
  def initialize(period)
    @scope = NotificationLog.where(created_at: period)
  end

  # Generate a list of duplicated gov request ID coming through from a single app
  # this would be a sign we are sending emails twice.
  def duplicates
    @scope
      .group(:emailing_app, :govuk_request_id)
      .having('COUNT(1) > 1')
      .pluck(:emailing_app, :govuk_request_id, 'ARRAY_AGG(gov_delivery_ids)')
  end

  # Report when a notification is sent by GovUkDelivery and not by EmailAlertApi.
  # * Data is grouped by the GovUkDelivery gov_delivery_ids field.
  def missing
    @missing ||= @scope
      .where(emailing_app: 'gov_uk_delivery')
      .joins(%(
        LEFT JOIN notification_logs eaa_notification_logs ON
          eaa_notification_logs.govuk_request_id = notification_logs.govuk_request_id AND
          eaa_notification_logs.emailing_app = 'email_alert_api'
        ))
      .where(eaa_notification_logs: { id: nil })
      .group('notification_logs.gov_delivery_ids::text')
      .count
  end

  # Report when both GovUkDelivery and EmailAlertApi have sent a notification,
  # but have the list of gov delivery topics that receive the notification don't match.
  # * Data is grouped by the gov_delivery_ids fields.
  def different
    @different ||= @scope
      .where(emailing_app: 'gov_uk_delivery')
      .joins(%(
        JOIN notification_logs eaa_notification_logs ON
          eaa_notification_logs.govuk_request_id = notification_logs.govuk_request_id AND
          eaa_notification_logs.emailing_app = 'email_alert_api' AND
          eaa_notification_logs.gov_delivery_ids::text != notification_logs.gov_delivery_ids::text
        ))
      .group('notification_logs.gov_delivery_ids::text', 'eaa_notification_logs.gov_delivery_ids::text')
      .count
  end
end

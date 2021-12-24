class UnpublicationNotifications < ApplicationController
  ALLOWED_NOTIFICATION_TEMPLATE = ["default"]

  def create
    head :bad_request and return unless allowed_notification_template?(params[:notification_template])
    head :not_found and return unless subscription_list

    email = UnpublicationNotificationBuilder.call(notification_template: params[:notification_template])
    SendEmailWorker.perform_async_in_queue(email.id, queue: :send_email_transactional)

    # Send Unsubscription Notification
    # Delete subscriber list
  end

private

  def subscription_list
    @subscription_list ||= SubscriberList.where(content_id: params[:content_id]))
  end

  def allowed_notification_template?(notification_template)
    ALLOWED_NOTIFICATION_TEMPLATE.include?(notification_template)
  end
end

class NotificationsController < ApplicationController
  def create
    NotificationWorker.perform_async(notification_params.to_json)

    render json: {message: "Notification queued for sending"}, status: 202
  end

private

  def notification_params
    params.slice(:subject, :body, :tags)
  end
end

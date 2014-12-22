class NotificationsController < ApplicationController
  def create
    NotificationWorker.perform_async(notification_params.to_json)

    respond_to do |format|
      format.json { render json: {message: "Notification queued for sending"}, status: 202 }
    end
  end

private

  def notification_params
    params.slice(:subject, :body, :tags, :from_address_id, :urgent, :header, :footer)
  end
end

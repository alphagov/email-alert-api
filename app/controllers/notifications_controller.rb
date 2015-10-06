class NotificationsController < ApplicationController
  def create
    query_field = notification_params[:links].present? ? :links : :tags
    NotificationWorker.perform_async(notification_params.to_json, query_field)

    respond_to do |format|
      format.json { render json: {message: "Notification queued for sending"}, status: 202 }
    end
  end

private

  def notification_params
    params.slice(:subject, :body, :tags, :from_address_id, :urgent, :header, :footer)
  end
end

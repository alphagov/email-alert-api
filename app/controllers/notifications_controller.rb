class NotificationsController < ApplicationController
  def create
    NotificationWorker.perform_async(notification_params)

    respond_to do |format|
      format.json { render json: {message: "Notification queued for sending"}, status: 202 }
    end
  end

private

  def notification_params
    params.slice(:subject, :from_address_id, :urgent, :header, :footer, :document_type)
      .merge(tags: params.fetch(:tags, {}))
      .merge(links: params.fetch(:links, {}))
      .merge(body: notification_body)
  end

  def notification_body
    GovukRequestId.insert(params[:body])
  end
end

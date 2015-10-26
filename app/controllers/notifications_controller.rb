class NotificationsController < ApplicationController
  def create
    # Ensure the Sidekiq worker receives a simple data type as its argument -
    # in this case a JSON string (rather than a Ruby hash).
    NotificationWorker.perform_async(notification_params.to_json)

    respond_to do |format|
      format.json { render json: {message: "Notification queued for sending"}, status: 202 }
    end
  end

private

  def notification_params
    params.slice(:subject, :body, :from_address_id, :urgent, :header, :footer)
      .merge(tags: params.fetch(:tags, {}))
      .merge(links: params.fetch(:links, {}))
  end
end

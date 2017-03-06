class NotificationLogsController < ApplicationController
  def create
    NotificationLog.create(notification_log_params)

    respond_to do |format|
      format.json { render json: {message: "Notification Log created"}, status: 202 }
    end
  end

private

  def notification_log_params
    params.permit(
      :govuk_request_id,
      :content_id,
      :public_updated_at,
      :document_type,
      :emailing_app,
      :publishing_app,
      gov_delivery_ids: []
    )
  end
end

class NotificationsController < ApplicationController
  def create
    NotificationWorker.perform_async(notification_params)

    Notification.build_from(params: notification_params.with_indifferent_access).save!

    respond_to do |format|
      format.json { render json: { message: "Notification queued for sending" }, status: 202 }
    end
  end

  def index
    render json: Services.gov_delivery.fetch_bulletins(params[:start_at])
  end

  def show
    render json: Services.gov_delivery.fetch_bulletin(params[:id])
  end

private

  def notification_params
    permitted_params = params.permit!.to_h
    permitted_params.slice(:subject, :from_address_id, :urgent, :header, :footer, :document_type,
      :content_id, :public_updated_at, :publishing_app, :email_document_supertype,
      :government_document_supertype)
      .merge(tags: permitted_params.fetch(:tags, {}))
      .merge(links: permitted_params.fetch(:links, {}))
      .merge(body: notification_body)
      .merge(govuk_request_id: GovukRequestId.govuk_request_id)
  end

  def notification_body
    GovukRequestId.insert(params[:body])
  end
end

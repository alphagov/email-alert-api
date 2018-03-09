class NotificationsController < ApplicationController
  def create
    return render_conflict if content_change_exists?

    NotificationHandlerService.call(
      params: notification_params,
      user: current_user,
    )

    render json: { message: "Notification queued for sending" }, status: 202
  end

  def index
    render json: {}
  end

  def show
    render json: {}
  end

private

  def notification_params
    permitted_params = params.permit!.to_h
    permitted_params.slice(:subject, :from_address_id, :urgent, :header, :footer, :document_type,
      :content_id, :public_updated_at, :publishing_app, :email_document_supertype,
      :government_document_supertype, :title, :description, :change_note, :base_path, :priority, :footnote)
      .merge(tags: permitted_params.fetch(:tags, {}))
      .merge(links: permitted_params.fetch(:links, {}))
      .merge(body: notification_body)
      .merge(govuk_request_id: GovukRequestId.govuk_request_id)
  end

  def notification_body
    GovukRequestId.insert(params[:body])
  end

  def render_conflict
    render json: { message: "Content change already received" }, status: 409
  end

  def content_change_exists?
    ContentChange.where(
      base_path: notification_params[:base_path],
      content_id: notification_params[:content_id],
      public_updated_at: notification_params[:public_updated_at]
    ).exists?
  end
end

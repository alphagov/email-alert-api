class ContentChangesController < ApplicationController
  def create
    return render_conflict if content_change_exists?

    ContentChangeHandlerService.call(
      params: content_change_params.to_h,
      user: current_user,
      govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
    )

    render json: { message: "Content change queued for sending" }, status: :accepted
  end

private

  def content_change_params
    params.permit(
      :subject,
      :from_address_id,
      :urgent,
      :header,
      :footer,
      :document_type,
      :content_id,
      :public_updated_at,
      :publishing_app,
      :email_document_supertype,
      :government_document_supertype,
      :title,
      :description,
      :change_note,
      :base_path,
      :priority,
      :footnote,
      tags: {},
      links: {},
    )
  end

  def render_conflict
    render json: { error: "Content change already received" }, status: :conflict
  end

  def content_change_exists?
    ContentChange.exists?(
      base_path: content_change_params[:base_path],
      content_id: content_change_params[:content_id],
      public_updated_at: content_change_params[:public_updated_at],
    )
  end
end

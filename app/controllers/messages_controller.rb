class MessagesController < ApplicationController
  def create
    return render_conflict if message_exists?

    MessageHandlerService.call(
      params: message_params.to_h,
      user: current_user,
      govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
    )

    render json: { message: "Content change queued for sending" }, status: 202
  end

private

  def message_params
    params.permit(:sender_message_id,
                  :title,
                  :url,
                  :body,
                  :document_type,
                  :email_document_supertype,
                  :government_document_supertype,
                  :priority,
                  links: {},
                  tags: {})
  end

  def render_conflict
    render json: { message: "Message already received" }, status: 409
  end

  def message_exists?
    return false unless message_params[:sender_message_id]

    Message.exists?(sender_message_id: message_params[:sender_message_id])
  end
end

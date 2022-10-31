class MessagesController < ApplicationController
  def create
    return render_conflict if message_exists?

    MessageHandlerService.call(
      params: message_params.to_h,
      user: current_user,
      govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
    )

    render json: { message: "Message queued for sending" }, status: :accepted
  end

private

  def message_params
    criteria_rules = params[:criteria_rules].each(&:permit!) if params[:criteria_rules].respond_to?(:each)

    params.permit(
      :sender_message_id,
      :title,
      :body,
      :priority,
    ).merge(
      criteria_rules:,
    )
  end

  def render_conflict
    render json: { message: "Message already received" }, status: :conflict
  end

  def message_exists?
    return false unless message_params[:sender_message_id]

    Message.exists?(sender_message_id: message_params[:sender_message_id])
  end
end

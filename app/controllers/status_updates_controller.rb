class StatusUpdatesController < ApplicationController
  wrap_parameters false

  rescue_from StatusUpdateService::DeliveryAttemptStatusConflictError do |e|
    render json: { error: e.message }, status: :conflict
  end

  rescue_from StatusUpdateService::DeliveryAttemptInvalidStatusError do |e|
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def create
    StatusUpdateService.call(
      sent_at: params[:sent_at],
      completed_at: params.require(:completed_at),
      reference: params.require(:reference),
      status: params.require(:status),
      user: current_user,
    )
    head :no_content
  end

private

  def authorise
    authorise_user!("status_updates")
  end
end

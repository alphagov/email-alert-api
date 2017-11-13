class StatusUpdatesController < ApplicationController
  wrap_parameters false

  def create
    StatusUpdateWorker.perform_async(**status_update_params)
    render plain: "queued for processing", status: :accepted
  end

private

  def status_update_params
    params.permit(:reference, :status).to_h.symbolize_keys
  end
end

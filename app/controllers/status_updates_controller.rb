class StatusUpdatesController < ApplicationController
  wrap_parameters false

  def create
    StatusUpdateService.call(**status_update_params)
    head :no_content
  end

private

  def status_update_params
    params.require(:reference)
    params.require(:status)
    params.permit(:reference, :status).to_h.symbolize_keys
  end
end

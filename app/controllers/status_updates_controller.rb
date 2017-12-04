class StatusUpdatesController < ApplicationController
  before_action :authorise_for_status_updates
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

  def authorise_for_status_updates
    authorise_user!("status_updates")
  end
end

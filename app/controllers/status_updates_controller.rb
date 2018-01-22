class StatusUpdatesController < ApplicationController
  wrap_parameters false

  def create
    StatusUpdateService.call(
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

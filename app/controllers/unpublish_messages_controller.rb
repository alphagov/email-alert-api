class UnpublishMessagesController < ApplicationController
  def create
    UnpublishHandlerService.call(
      unpublishing_params[:content_id]
    )

    render json: { message: "Unpublish message queued for sending" }, status: 202
  end

private

  def unpublishing_params
    permitted_params = params.permit!.to_h
    permitted_params.slice(:content_id)
  end
end

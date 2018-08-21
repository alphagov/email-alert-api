class UnpublishMessagesController < ApplicationController
  def create
    UnpublishHandlerService.call(
      unpublishing_params[:content_id], unpublishing_params.dig(:redirects, 0, :destination)
      )

    render json: { message: "Unpublish message queued for sending" }, status: 202
  end

private

  def unpublishing_params
    @_params ||= params.permit(:content_id, redirects: :destination)
  end
end

class UnpublishMessagesController < ApplicationController
  def create
    redirect_path = unpublishing_params.dig(:redirects, 0, :destination)
    UnpublishHandlerService.call(
      unpublishing_params[:content_id], ContentItem.new(redirect_path)
    )

    render json: { message: "Unpublish message queued for sending" }, status: :accepted
  end

private

  def unpublishing_params
    @unpublishing_params ||= params.permit(:content_id, redirects: :destination)
  end
end

class SubscriptionsController < ActionController::Base
  def create
    render json: {}, status: :created
  end

private

  def subscription_params
    params.require(:address)
    params.require(:subscribable_id)
    params.permit(:address, :subscribable_id)
  end
end

class SubscriptionsController < ActionController::Base
  def create
    render json: {}, status: :created
  end
end

class SubscriptionsAuthTokenController < ApplicationController
  def auth_token
    render json: {}, status: :ok
  end
end

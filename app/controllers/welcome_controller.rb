class WelcomeController < ApplicationController
  def index
    message = "Welcome to Email Alert API. For source code and documentation"\
      " please visit: https://github.com/alphagov/email-alert-api"
    render json: { message: }
  end
end

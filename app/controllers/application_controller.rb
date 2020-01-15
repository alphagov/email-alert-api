class ApplicationController < ActionController::API
  include GDS::SSO::ControllerMethods

  before_action :authorise

  rescue_from ActiveRecord::RecordInvalid do |exception|
    render json: { error: "Unprocessable Entity",
                   details: exception.record&.errors&.messages },
           status: :unprocessable_entity
  end

private

  def authorise
    authorise_user!("internal_app")
  end
end

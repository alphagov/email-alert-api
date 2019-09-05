class ApplicationController < ActionController::API
  include GDS::SSO::ControllerMethods

  before_action :authorise

  rescue_from ActiveRecord::RecordInvalid do |exception|
    render json: { message: "Unprocessable Entity",
                   errors: exception.record.errors.messages },
           status: :unprocessable_entity
  end

private

  def authorise
    authorise_user!("internal_app")
  end
end

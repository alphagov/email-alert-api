class ApplicationController < ActionController::API
  include GDS::SSO::ControllerMethods

  before_action :authorise

  rescue_from ActiveRecord::RecordInvalid do |exception|
    render_unprocessable(exception.record&.errors&.messages)
  end

private

  def render_unprocessable(messages)
    render json: { error: "Unprocessable Entity",
                   details: messages },
           status: :unprocessable_entity
  end

  def authorise
    authorise_user!("internal_app")
  end
end

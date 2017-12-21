class ApplicationController < ActionController::API
  include GDS::SSO::ControllerMethods

  before_action :authorise

private

  def authorise
    authorise_user!("internal_app")
  end
end

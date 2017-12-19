class ApplicationController < ActionController::API
  include GDS::SSO::ControllerMethods

  before_action :log_missing_credentials

private

  def log_missing_credentials
    auth_header = request.env["HTTP_AUTHORIZATION"]
    if auth_header.present?
      authenticate_user!
      check_for_valid_and_permitted
    else
      logger.error "Missing bearer token from #{request_user_agent} - #{request_path}"
    end
  end

  def check_for_valid_and_permitted
    if user_signed_in?
      unless current_user.has_permission?("internal_app")
        logger.error "Missing internal_app permission from #{request_user_agent} - #{request_path}"
      end
    else
      logger.error "Invalid bearer token from #{request_user_agent} - #{request_path}"
    end
  end

  def request_user_agent
    request.env["HTTP_USER_AGENT"]
  end

  def request_path
    "#{controller_path}##{action_name}"
  end
end

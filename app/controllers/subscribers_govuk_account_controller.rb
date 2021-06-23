class SubscribersGovukAccountController < ApplicationController
  before_action :validate_params

  def authenticate
    account_response = GdsApi.account_api.get_attributes(
      attributes: %i[email email_verified],
      govuk_account_session: expected_params[:govuk_account_session],
    )

    email_verified = account_response.dig("values", "email_verified")
    email = account_response.dig("values", "email")

    api_response = { govuk_account_session: account_response["govuk_account_session"] }.compact

    render status: :forbidden, json: api_response and return unless email_verified
    render status: :not_found, json: api_response and return unless email

    subscriber = Subscriber.find_by_address(email)
    render status: :not_found, json: api_response and return unless subscriber

    render json: api_response.merge(subscriber: subscriber)
  rescue GdsApi::HTTPUnauthorized
    head :unauthorized
  end

private

  def expected_params
    params.permit(:govuk_account_session)
  end

  def validate_params
    ParamsValidator.new(expected_params).validate!
  end

  class ParamsValidator < OpenStruct
    include ActiveModel::Validations

    validates :govuk_account_session, presence: true
  end
end

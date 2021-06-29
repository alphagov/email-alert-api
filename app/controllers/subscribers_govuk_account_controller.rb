class SubscribersGovukAccountController < ApplicationController
  before_action :validate_params

  before_action do
    account_response = GdsApi.account_api.get_user(
      govuk_account_session: expected_params[:govuk_account_session],
    )

    @govuk_account_id = account_response["id"]
    email = account_response["email"]
    email_verified = account_response["email_verified"]

    @api_response = { govuk_account_session: account_response["govuk_account_session"] }.compact

    if !email
      render status: :forbidden, json: @api_response
    elsif !email_verified
      render status: :forbidden, json: @api_response
    else
      @subscriber = Subscriber.resilient_find_or_create(email, signon_user_uid: current_user.uid)
    end
  rescue GdsApi::HTTPUnauthorized
    head :unauthorized
  end

  def authenticate
    render json: api_response.merge(subscriber: subscriber)
  end

  def link_subscriber_to_account
    subscriber.update!(govuk_account_id: govuk_account_id)
    render json: api_response.merge(subscriber: subscriber)
  end

private

  attr_reader :api_response, :govuk_account_id, :subscriber

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

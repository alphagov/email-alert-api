class SubscribersGovukAccountController < ApplicationController
  before_action :get_user_from_account_api, only: %i[authenticate link_subscriber_to_account]

  def show
    head :unprocessable_entity and return unless params.fetch(:govuk_account_id)

    subscriber = Subscriber.find_by(govuk_account_id: params.fetch(:govuk_account_id))

    if subscriber
      render json: { subscriber: }
    else
      head :not_found
    end
  end

  def authenticate
    render json: api_response.merge(subscriber:)
  end

  def link_subscriber_to_account
    previously_linked = !subscriber.govuk_account_id.nil?
    subscriber.update!(govuk_account_id:)

    unless previously_linked || subscriber.active_subscriptions.empty?
      email = LinkedAccountEmailBuilder.call(
        subscriber:,
      )

      SendEmailJob.perform_async_in_queue(
        email.id,
        queue: :send_email_transactional,
      )
    end

    render json: api_response.merge(subscriber:)
  end

private

  attr_reader :api_response, :govuk_account_id, :subscriber

  def get_user_from_account_api
    head :unprocessable_entity and return unless params.fetch(:govuk_account_session)

    account_response = GdsApi.account_api.get_user(
      govuk_account_session: params.fetch(:govuk_account_session),
    )

    @govuk_account_id = account_response["id"]
    email = account_response["email"]
    email_verified = account_response["email_verified"]

    @api_response = { govuk_account_session: account_response["govuk_account_session"] }.compact

    render status: :forbidden, json: @api_response and return unless email
    render status: :forbidden, json: @api_response and return unless email_verified

    @subscriber = Subscriber.resilient_find_or_create(email, signon_user_uid: current_user.uid)
  rescue GdsApi::HTTPUnauthorized
    head :unauthorized
  end
end

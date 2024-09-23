require "ostruct"

class SubscriptionsAuthTokenController < ApplicationController
  before_action :validate_params

  def auth_token
    subscriber_list = SubscriberList.find_by!(slug: expected_params[:topic_id])
    token = generate_token
    email = build_email(token, subscriber_list)

    SendEmailWorker
      .perform_async_in_queue(email.id, queue: :send_email_transactional)

    render json: {}, status: :ok
  end

  def generate_token
    AuthTokenGeneratorService.call(expected_params.to_h.symbolize_keys)
  end

  def build_email(token, subscriber_list)
    SubscriptionAuthEmailBuilder.call(
      address: expected_params[:address],
      token:,
      subscriber_list:,
      frequency: expected_params[:frequency],
    )
  end

  def validate_params
    validator = ParamsValidator.new(expected_params)
    render_unprocessable(validator.errors.messages) unless validator.valid?
  end

  def expected_params
    params.permit(:address, :topic_id, :frequency)
  end

  class ParamsValidator < OpenStruct
    include ActiveModel::Validations

    validates :address, email_address: true, presence: true
    validates :topic_id, presence: true
    validates :frequency, presence: true, inclusion: { in: Subscription.frequencies.keys }
  end
end

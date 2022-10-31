class SubscribersAuthTokenController < ApplicationController
  before_action :validate_params

  def auth_token
    subscriber = Subscriber.find_by_address!(expected_params[:address])
    head :forbidden and return if subscriber.linked_to_govuk_account?

    token = generate_token(subscriber)
    email = build_email(subscriber, token)

    SendEmailWorker
      .perform_async_in_queue(email.id, queue: :send_email_transactional)

    render json: { subscriber: }, status: :created
  end

private

  def generate_token(subscriber)
    AuthTokenGeneratorService.call("subscriber_id" => subscriber.id)
  end

  def build_email(subscriber, token)
    SubscriberAuthEmailBuilder.call(
      subscriber:,
      destination: expected_params[:destination],
      token:,
    )
  end

  def expected_params
    params.permit(:address, :destination)
  end

  def validate_params
    validator = ParamsValidator.new(expected_params)
    render_unprocessable(validator.errors.messages) unless validator.valid?
  end

  class ParamsValidator < OpenStruct
    include ActiveModel::Validations

    validates :address, presence: true
    validates :address, email_address: true, allow_blank: true

    validates :destination, presence: true
    validates :destination, root_relative_url: true, allow_blank: true
  end
end

class SubscriptionsAuthTokenController < ApplicationController
  before_action :validate_params

  def auth_token
    address = params.fetch(:address)
    topic_id = params.fetch(:topic_id)
    frequency = params.fetch(:frequency)

    token = AuthTokenGeneratorService.call(address: address, topic_id: topic_id, frequency: frequency)
    email = SubscriptionAuthEmailBuilder.call(address: address, token: token, topic_id: topic_id, frequency: frequency)

    do_send email
    render json: {}, status: :ok
  end

  def do_send(email)
    SendEmailWorker
      .perform_async_in_queue(email.id, queue: :send_email_transactional)
  end

  def validate_params
    ParamsValidator.new(expected_params).validate!
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

class SubscriptionsAuthTokenController < ApplicationController
  before_action :validate_params

  def auth_token
    render json: {}, status: :ok
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

class SubscribersAccountJwtController < ApplicationController
  before_action :validate_params

  class TokenInvalid < RuntimeError; end

  rescue_from TokenInvalid do |exception|
    render json: { error: "Could not fetch subscriber",
                   details: exception.message },
           status: :forbidden
  end

  def account_jwt
    jwt = expected_params.require(:jwt)
    address = validate_token(jwt)
    subscriber = find_subscriber(address)

    render json: { subscriber: subscriber }
  end

private

  def validate_token(jwt)
    payload, = JWT.decode jwt, public_key, true, { algorithm: "ES256" }
    raise TokenInvalid, "email address not verified" unless payload["email_verified"]

    payload["email"]
  rescue JWT::DecodeError
    raise TokenInvalid, "could not decode jwt"
  end

  def public_key
    OpenSSL::PKey::EC.new(Rails.application.secrets.accounts_jwt_public_key)
  end

  def find_subscriber(address)
    Subscriber.resilient_find_or_create(
      address,
      signon_user_uid: current_user.uid,
    ).tap do |subscriber|
      subscriber.activate if subscriber.deactivated?
    end
  end

  def expected_params
    params.permit(:jwt)
  end

  def validate_params
    ParamsValidator.new(expected_params).validate!
  end

  class ParamsValidator < OpenStruct
    include ActiveModel::Validations

    validates :jwt, presence: true
  end
end

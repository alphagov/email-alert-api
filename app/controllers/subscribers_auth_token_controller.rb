class SubscribersAuthTokenController < ApplicationController
  # @TODO - there is no validation here

  def auth_token
    subscriber = find_or_create_subscriber(expected_params.require(:address))
    token = generate_token(subscriber)
    email = build_email(subscriber, token)

    DeliveryRequestWorker
      .perform_async_in_queue(email.id, queue: :delivery_immediate_high)

    render json: { subscriber: subscriber }, status: :created
  end

private

  def find_or_create_subscriber(address)
    found = Subscriber.find_by_address(address)
    found.activate! if found&.deactivated?
    found || Subscriber.create!(
      address: address,
      signon_user_uid: current_user.uid,
    )
  end

  def generate_token(subscriber)
    AuthTokenGeneratorService.call(
      subscriber,
      redirect: expected_params[:redirect],
      expiry: 1.week.from_now
    )
  end

  def build_email(subscriber, token)
    AuthEmailBuilder.call(
      subscriber: subscriber,
      destination: expected_params.require(:destination),
      token: token,
    )
  end

  def expected_params
    params.permit(:address, :destination, :redirect)
  end
end

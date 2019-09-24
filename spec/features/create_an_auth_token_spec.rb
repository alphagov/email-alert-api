RSpec.describe "Create an auth token", type: :request do
  before do
    allow_any_instance_of(DeliveryRequestService)
      .to receive(:provider_name).and_return("notify")

    stub_notify
  end

  around do |example|
    Timecop.freeze do
      Sidekiq::Testing.inline! { example.run }
    end
  end

  let(:address) { "test@example.com" }
  let!(:subscriber) { create(:subscriber, address: address) }
  let(:destination) { "/authenticate" }
  let(:redirect) { "/logged-in-page" }

  scenario "successful auth token" do
    login_with_internal_app

    post "/subscribers/auth-token", params: {
      address: address,
      destination: destination,
      redirect: redirect,
    }

    notify_email_stub = notify_email(subscriber, destination, redirect)
    expect(response.status).to be 201
    expect(notify_email_stub).to have_been_requested
  end

  def notify_email(subscriber, destination, redirect)
    sign_in_link = generate_sign_in_link(subscriber, destination, redirect)

    stub_request(:post, "http://fake-notify.com/v2/notifications/email")
      .with(
        "body" => hash_including(
          "email_address" => subscriber.address,
          "personalisation" => hash_including(
            "subject" => "Confirm your email address",
            "body" => include(sign_in_link),
          ),
        ),
      )
      .to_return(body: {}.to_json)
  end

  def generate_sign_in_link(subscriber, destination, redirect)
    token = generate_token(subscriber, redirect)
    "http://www.dev.gov.uk#{destination}?token=#{token}"
  end

  def generate_token(subscriber, redirect)
    data = {
      "data" => {
        "subscriber_id" => subscriber.id,
        "redirect" => redirect,
      },
      "exp" => 1.week.from_now.to_i,
      "iat" => Time.now.to_i,
      "iss" => "https://www.gov.uk",
    }
    secret = Rails.application.secrets.email_alert_auth_token
    JWT.encode(data, secret, "HS256")
  end
end

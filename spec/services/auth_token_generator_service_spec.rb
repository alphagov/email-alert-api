RSpec.describe AuthTokenGeneratorService do
  describe ".call" do
    let(:subscriber) { create(:subscriber) }
    let(:secret) { Rails.application.secrets.email_alert_auth_token }
    let(:algorithim) { "HS256" }
    let(:expiry) { 1.day.from_now }

    subject(:token) { described_class.call(subscriber, redirect: nil, expiry: expiry) }

    it { is_expected.to be_a(String) }

    it "can be decoded" do
      Timecop.freeze do
        decoded = JWT.decode(token, secret, true, algorithim: algorithim)

        expect(decoded).to include(
          a_hash_including(
            "data" => a_hash_including(
              "subscriber_id" => subscriber.id,
              "redirect" => nil,
            ),
            "exp" => expiry.to_i,
            "iat" => Time.now.to_i,
            "iss" => "https://www.gov.uk",
          ),
        )
      end
    end
  end
end

RSpec.describe AuthTokenGeneratorService do
  describe ".call" do
    let(:subscriber) { create(:subscriber) }
    let(:secret) { Rails.application.secrets.email_alert_auth_token }
    let(:algorithim) { "HS256" }

    subject(:token) { described_class.call(subscriber) }

    it { is_expected.to be_a(String) }

    it "can be decoded to include a subscriber_id" do
      decoded = JWT.decode(token, secret, true, algorithim: algorithim)
      expect(decoded).to match(
        a_hash_including(
          "data" => { "subscriber_id" => subscriber.id }
        )
      )
    end
  end
end

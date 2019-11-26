RSpec.describe AuthTokenGeneratorService do
  describe ".call" do
    let(:secret) { Rails.application.secrets.email_alert_auth_token }
    let(:algorithim) { "HS256" }
    let(:expiry) { 1.day.from_now }
    let(:data) do
      {
        token: "token_data_string",
        id: "id",
      }
    end

    subject(:token) { described_class.call(data, expiry: expiry) }

    it { is_expected.to be_a(String) }

    it "can be decoded" do
      Timecop.freeze do
        decoded = JWT.decode(token, secret, true, algorithim: algorithim)

        expect(decoded).to include(
          "data" => data.stringify_keys,
          "exp" => expiry.to_i,
          "iat" => Time.now.to_i,
          "iss" => "https://www.gov.uk",
          )
      end
    end
  end
end

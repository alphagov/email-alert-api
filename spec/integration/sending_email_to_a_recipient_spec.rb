RSpec.describe "Sending an email to a recipient" do
  let(:email) { create(:email, address: original_address) }
  let(:original_address) { "original@example.com" }
  let(:environment) do
    {
      EMAIL_SERVICE_PROVIDER: "notify",
      EMAIL_ADDRESS_OVERRIDE: email_address_override,
      EMAIL_ADDRESS_OVERRIDE_WHITELIST: email_address_override_whitelist,
    }
  end
  let(:email_address_override) { nil }
  let(:email_address_override_whitelist) { nil }

  def expect_notify_request_for(email_address:)
    request = a_request(:post, /fake-notify/)
        .with(body: hash_including(email_address: email_address))
    expect(request).to have_been_made
  end

  before { stub_request(:post, /fake-notify/).to_return(body: {}.to_json) }

  around do |example|
    config = EmailAlertAPI.config
    ClimateControl.modify(environment) do
      EmailAlertAPI.config = EmailAlertAPI::Config.new(Rails.env)
      example.run
    end
    EmailAlertAPI.config = config
  end

  context "when an override is not set" do
    it "sends an email to the original address" do
      SendEmailService.call(email: email)
      expect_notify_request_for(email_address: original_address)
    end
  end

  context "when override is set" do
    let(:email_address_override) { "override@example.com" }

    it "sends an email to the override address" do
      SendEmailService.call(email: email)
      expect_notify_request_for(email_address: "override@example.com")
    end
  end

  context "when override is set with an override whitelist" do
    let(:email_address_override) { "override@example.com" }
    let(:email_address_override_whitelist) do
      "whitelist-1@example.com, whitelist-2@example.com, whitelist-3@example.com"
    end
    let(:original_address) { "whitelist-1@example.com" }

    it "sends to the whitelist address" do
      SendEmailService.call(email: email)
      expect_notify_request_for(email_address: "whitelist-1@example.com")
    end
  end
end

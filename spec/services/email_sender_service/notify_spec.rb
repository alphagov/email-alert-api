require "notifications/client"

RSpec.describe EmailSenderService::Notify do
  describe "#call" do
    let(:api_key) { nil }
    let(:base_url) { nil }
    let(:template_id) { "21a3289b-0074-4223-ad94-1cdc6d153da0" }

    before do
      allow(EmailAlertAPI.config).to receive(:notify).and_return(
        api_key: api_key,
        template_id: template_id,
        base_url: base_url,
      )
    end

    let(:client) { double }

    before do
      allow(Notifications::Client)
        .to receive(:new)
        .and_return(client)

      allow(client).to receive(:send_email)
        .and_return(double(id: 0))
    end

    it "sends an email to the address passed in" do
      expect(client)
        .to receive(:send_email)
        .with(
          email_address: "email@address.com",
          personalisation: a_hash_including(subject: "subject", body: "body"),
          template_id: template_id,
        )

      subject.call(address: "email@address.com", subject: "subject", body: "body")
    end

    it "uses the default base url" do
      expect(Notifications::Client)
        .to receive(:new)
        .with(api_key, nil)

      subject.call(address: "email@address.com", subject: "subject", body: "body")
    end

    context "with a custom base url" do
      let(:base_url) { "https://api.notifications" }

      it "configures the client with the correct base url" do
        expect(Notifications::Client)
          .to receive(:new)
          .with(api_key, base_url)

        subject.call(address: "email@address.com", subject: "subject", body: "body")
      end
    end
  end
end

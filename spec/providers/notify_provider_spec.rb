RSpec.describe NotifyProvider do
  describe ".call" do
    let(:template_id) { EmailAlertAPI.config.notify.fetch(:template_id) }
    let(:arguments) do
      {
        address: "email@address.com",
        subject: "subject",
        body: "body",
        reference: "ref-123",
      }
    end
    let(:notify_client) { instance_double("Notifications::Client") }

    it "calls the Notifications client" do
      allow(Notifications::Client).to receive(:new).and_return(notify_client)
      expect(notify_client).to receive(:send_email)
        .with(
          email_address: "email@address.com",
          template_id: template_id,
          reference: "ref-123",
          personalisation: {
            subject: "subject",
            body: "body",
          },
        )

      described_class.call(arguments)
    end

    it "returns a sent status for a successful request" do
      stub_request(:post, /fake-notify/).to_return(body: {}.to_json)
      return_value = described_class.call(arguments)
      expect(return_value).to be(:sent)
    end

    it "returns a provider_communication_failure status for a Notify RequestError" do
      error_response = double(code: 404, body: "an error")
      allow(Notifications::Client).to receive(:new).and_return(notify_client)
      allow(notify_client).to receive(:send_email)
        .and_raise(Notifications::Client::RequestError.new(error_response))

      expect(described_class.call(arguments))
        .to be(:provider_communication_failure)
    end

    it "returns a provider_communication_failure status for a Notify Timeout" do
      allow(Notifications::Client).to receive(:new).and_return(notify_client)
      allow(notify_client).to receive(:send_email).and_raise(Net::OpenTimeout)

      expect(described_class.call(arguments))
        .to be(:provider_communication_failure)
    end

    it "returns a provider_communication_failure status for a Notify rejecting an email address" do
      error_response = double(
        code: 400,
        body: {
          errors: [
            {
              error: "ValidationError",
              message: "email_address Not a valid email address",
            },
          ],
        }.to_json,
      )
      allow(Notifications::Client).to receive(:new).and_return(notify_client)
      allow(notify_client).to receive(:send_email)
        .and_raise(Notifications::Client::BadRequestError.new(error_response))

      expect(described_class.call(arguments))
        .to be(:undeliverable_failure)
    end
  end
end

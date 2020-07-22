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

    it "calls the Notifications client" do
      client = instance_double("Notifications::Client")
      allow(Notifications::Client).to receive(:new).and_return(client)

      expect(client).to receive(:send_email)
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

    context "when it sends successfully" do
      before { stub_request(:post, /fake-notify/).to_return(body: {}.to_json) }

      it "returns a status of sending" do
        return_value = described_class.call(arguments)
        expect(return_value).to be(:sending)
      end
    end

    context "when an error occurs" do
      before do
        error_response = double(code: 404, body: "an error")
        allow_any_instance_of(Notifications::Client).to receive(:send_email)
          .and_raise(Notifications::Client::RequestError.new(error_response))
      end

      it "returns a status of provider_communication_failure" do
        return_value = described_class.call(arguments)
        expect(return_value).to be(:provider_communication_failure)
      end

      it "notifies GovukError" do
        expect(GovukError).to receive(:notify)
        described_class.call(arguments)
      end

      context "and it's an invalid email address error" do
        before do
          error_response = double(code: 404, body: '{"errors": [{"error": "ValidationError", "message": "email_address Not a valid email address"}]}')
          allow_any_instance_of(Notifications::Client).to receive(:send_email)
            .and_raise(Notifications::Client::BadRequestError.new(error_response))
        end

        it "does not notify GovukError" do
          expect(GovukError).not_to receive(:notify)
          described_class.call(arguments)
        end
      end
    end
  end
end

RSpec.describe SendEmailService::SendNotifyEmail do
  describe ".call" do
    let(:email) { create(:email) }
    let(:notify_client) do
      instance_double("Notifications::Client", send_email: nil)
    end

    before do
      allow(Notifications::Client).to receive(:new).and_return(notify_client)
      Rails.application.config.notify_template_id = "Hello!"
    end

    it "uses a Notifications::Client to send an email" do
      described_class.call(email)

      expect(notify_client).to have_received(:send_email).with(
        email_address: email.address,
        template_id: Rails.application.config.notify_template_id,
        reference: email.id,
        personalisation: {
          subject: email.subject,
          body: email.body,
        },
      )
    end

    it "marks the email as sent when sending is successful" do
      freeze_time do
        expect { described_class.call(email) }
          .to change { email.reload.status }.to("sent")
          .and change { email.reload.sent_at }.to(Time.zone.now)
      end
    end

    context "with a subscription id passed in" do
      let!(:subscription) { create(:subscription) }
      let(:email) { create(:email, subscription_id: subscription.id) }

      it "includes a one-click unsubscribe parameter" do
        described_class.call(email)

        expect(notify_client).to have_received(:send_email).with(
          email_address: email.address,
          template_id: Rails.application.config.notify_template_id,
          one_click_unsubscribe_url: /\/email\/unsubscribe\/one-click\/#{subscription.id}.*token=/,
          reference: email.id,
          personalisation: {
            subject: email.subject,
            body: email.body,
          },
        )
      end
    end

    context "when there is no subscription" do
      let(:email) { create(:email, subscription_id: nil) }

      it "includes a one-click unsubscribe parameter" do
        described_class.call(email)

        expect(notify_client).to have_received(:send_email).with(
          email_address: email.address,
          template_id: Rails.application.config.notify_template_id,
          reference: email.id,
          personalisation: {
            subject: email.subject,
            body: email.body,
          },
        )
      end
    end

    it "marks an email as failed when it is sent to an invalid email address" do
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
      allow(notify_client).to receive(:send_email)
        .and_raise(Notifications::Client::BadRequestError.new(error_response))

      expect { described_class.call(email) }
        .to change { email.reload.status }.to("failed")
    end

    it "marks an email as failed when it is too long" do
      error_response = double(
        code: 400,
        body: {
          errors: [
            {
              error: "BadRequestError",
              message: "Your message is too long. Emails cannot be longer than 1000000 bytes.",
            },
          ],
        }.to_json,
      )
      allow(notify_client).to receive(:send_email)
        .and_raise(Notifications::Client::BadRequestError.new(error_response))

      expect { described_class.call(email) }
        .to change { email.reload.status }.to("failed")
    end

    it "raises a SendEmailService::NotifyCommunicationFailure error for transient Notify failings" do
      expected_errors = [
        Notifications::Client::RequestError.new(double(code: 404, body: "not found")),
        Net::OpenTimeout,
        Net::ReadTimeout,
        SocketError,
      ]

      expected_errors.each do |error|
        allow(notify_client).to receive(:send_email).and_raise(error)

        expect { described_class.call(email) }
          .to raise_error(SendEmailService::NotifyCommunicationFailure)
      end
    end
  end
end

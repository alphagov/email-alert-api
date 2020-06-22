RSpec.describe DeliveryRequestService do
  let(:config) { EmailAlertAPI.config.email_service }

  describe "#provider_name" do
    it "defaults to 'pseudo'" do
      expect(subject.provider_name).to eq("pseudo")
    end

    it "downcases the provider from the config" do
      subject = described_class.new(config: config.merge(provider: "NOTIFY"))
      expect(subject.provider_name).to eq("notify")
    end
  end

  describe "#provider" do
    it "defaults to the PseudoProvider" do
      expect(subject.provider).to eq(PseudoProvider)
    end

    it "can be configured" do
      subject = described_class.new(config: config.merge(provider: "NOTIFY"))
      expect(subject.provider).to eq(NotifyProvider)
    end
  end

  describe "#subject_prefix" do
    it "defaults to be an empty string" do
      expect(subject.subject_prefix).to eq("")
    end

    it "can be configured" do
      subject = described_class.new(config: config.merge(email_subject_prefix: "STAGING - "))
      expect(subject.subject_prefix).to eq("STAGING - ")
    end
  end

  shared_examples "records a statistic" do |status|
    it "records a #{status} statistic" do
      expect(GovukStatsd).to receive(:increment).with("delivery_attempt.status.#{status.underscore}")
      subject.call(email: email)
    end
  end

  describe "#call" do
    let!(:email) { create(:email) }

    around { |example| freeze_time { example.run } }

    it "calls the provider" do
      expect(subject.provider).to receive(:call)
        .with(
          hash_including(
            address: "test@example.com",
            subject: "subject",
            body: "body",
          ),
        )
        .and_return(:sending)

      attempted = subject.call(email: email)
      expect(attempted).to be true
    end

    context "when the provider raises an exception" do
      before do
        expect(subject.provider).to receive(:call).and_raise("Unknown error!")
      end

      it "sets the status to internal_failure" do
        subject.call(email: email)
        expect(DeliveryAttempt.last.status).to eq("internal_failure")
      end

      include_examples "records a statistic", "internal_failure"
    end

    context "when the provider raises a technical failure exception" do
      before do
        expect(subject.provider).to receive(:call).and_return(:technical_failure)
      end

      it "sets the status to technical_failure" do
        subject.call(email: email)
        expect(DeliveryAttempt.last.status).to eq("technical_failure")
      end

      it "adds a completed_at time" do
        subject.call(email: email)
        expect(DeliveryAttempt.last.completed_at).not_to be(nil)
      end

      include_examples "records a statistic", "technical_failure"
    end

    context "when the email address is overridden" do
      let(:subject) do
        described_class.new(config: config.merge(email_address_override: address))
      end

      let(:address) { "overridden@example.com" }

      it "calls the provider with the overridden email address" do
        expect(subject.provider).to receive(:call)
          .with(hash_including(address: address))
          .and_return(:sending)

        subject.call(email: email)
      end

      it "logs the email address is overriden" do
        expect(Rails.logger).to receive(:info)
          .with(match(/Overriding email address/))
        subject.call(email: email)
      end
    end

    context "when the email address isn't whitelisted" do
      let(:subject) do
        described_class.new(config: config.merge(
          email_address_override: "overridden@example.com", email_address_override_whitelist_only: true,
        ))
      end

      it "doesn't call the provider with the overridden email address" do
        expect(subject.provider).to_not receive(:call)

        attempted = subject.call(email: email)
        expect(attempted).to be false
      end
    end

    it "prefixes the subject if configured to do so" do
      subject = described_class.new(config: config.merge(email_subject_prefix: "STAGING - "))
      expect(subject.subject_prefix).to eq("STAGING - ")

      expect(subject.provider).to receive(:call)
        .with(
          hash_including(
            subject: "STAGING - subject",
          ),
        )
        .and_return(:sending)

      subject.call(email: email)
    end

    it "creates a delivery attempt" do
      expect { subject.call(email: email) }
        .to change(DeliveryAttempt, :count).by(1)
    end

    it "associates the delivery attempt with the email" do
      subject.call(email: email)
      expect(DeliveryAttempt.last.email).to eq(email)
    end

    context "when the delivery attempt returns a final status" do
      before { allow(subject.provider).to receive(:call).and_return(:delivered) }

      it "sets the delivery attempt's status to provider response" do
        subject.call(email: email)
        expect(DeliveryAttempt.last).to be_delivered
      end

      include_examples "records a statistic", "delivered"
    end

    it "sets the delivery attempt's provider to the name of the provider" do
      subject.call(email: email)
      expect(DeliveryAttempt.last.provider).to eq("pseudo")
    end

    it "sets the reference to same string that was sent the provider" do
      reference = nil
      expect(subject.provider).to receive(:call)
        .with(->(params) { reference = params.fetch(:reference) })
        .and_return(:sending)

      subject.call(email: email)

      expect(reference).to be_present
      expect(DeliveryAttempt.last.id).to eq(reference)
    end

    it "records a metric for the delivery attempt" do
      expect(MetricsService).to receive(:email_created_to_first_delivery_attempt)
        .with(email.created_at, Time.now.utc)

      subject.call(email: email)
    end

    it "records a metric for the request to the provdier" do
      expect(MetricsService).to receive(:email_send_request)
        .with("pseudo")
        .and_return(:sending)

      subject.call(email: email)
    end

    context "when the email is the first attempt of a content change" do
      let(:subscription_content) { create(:subscription_content, email: email) }

      it "records a metric for the time between content change creation time and delivery attempt" do
        content_change = subscription_content.content_change

        expect(MetricsService).to receive(:content_change_created_to_first_delivery_attempt)
          .with(content_change.created_at, Time.now.utc)

        subject.call(email: email)
      end
    end
  end
end

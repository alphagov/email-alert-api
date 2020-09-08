RSpec.describe StatusUpdateService do
  describe ".call" do
    let!(:delivery_attempt) { create(:delivery_attempt, id: reference, email: email) }
    let(:email) { create(:email) }
    let(:reference) { SecureRandom.uuid }
    let(:status) { "delivered" }
    let(:time) { Time.zone.now.beginning_of_minute }
    let(:user) { create(:user) }

    let(:args) do
      {
        reference: reference,
        status: status,
        completed_at: time,
        sent_at: time,
        user: user,
      }
    end

    it "updates the delivery attempt record" do
      described_class.call(**args)
      expect(delivery_attempt.reload)
        .to have_attributes(sent_at: time,
                            completed_at: time,
                            signon_user_uid: user.uid)
    end

    context "when provided a 'delivered' status" do
      let(:status) { "delivered" }

      it "sets the delivery attempt status to delivered" do
        expect { described_class.call(**args) }
          .to change { delivery_attempt.reload.status }.to("delivered")
          .and change { email.reload.finished_sending_at }.to(time)
      end
    end

    context "when provided a 'permanent-failure' status" do
      let(:status) { "permanent-failure" }
      let(:subscriber) { create(:subscriber) }
      let(:email) { create(:email, subscriber_id: subscriber.id, address: subscriber.address) }

      it "sets the delivery attempt status to undeliverable_failure" do
        expect { described_class.call(**args) }
          .to change { delivery_attempt.reload.status }
          .to("undeliverable_failure")
      end

      it "unsubscribes the subscriber from any existing subscriptions" do
        expect(UnsubscribeAllService).to receive(:call)
                                     .with(subscriber, :non_existent_email)
        described_class.call(**args)
      end
    end

    context "when provided a 'temporary-failure' status" do
      let(:status) { "temporary-failure" }

      it "sets the delivery attempt status to undeliverable_failure" do
        expect { described_class.call(**args) }
          .to change { delivery_attempt.reload.status }.to("undeliverable_failure")
          .and change { email.reload.finished_sending_at }.to(time)
      end
    end

    context "when provided with an unexpected status" do
      let(:status) { "surprise-failure" }

      it "raises a DeliveryAttemptInvalidStatusError and notifies GovukError" do
        message = "Recieved an unexpected status: 'surprise-failure'"
        expect(GovukError).to receive(:notify).with(message)
        expect { described_class.call(**args) }
          .to raise_error(StatusUpdateService::DeliveryAttemptInvalidStatusError,
                          message)
      end
    end

    context "when the delivery attempt isn't in a sent state" do
      let!(:delivery_attempt) do
        create(:delivered_delivery_attempt, id: reference, email: email)
      end

      it "raises a DeliveryAttemptStatusConflictError" do
        expect { described_class.call(**args) }
          .to raise_error(StatusUpdateService::DeliveryAttemptStatusConflictError,
                          "Status update already received")
      end
    end
  end
end

RSpec.describe StatusUpdateService do
  let!(:delivery_attempt) do
    create(:delivery_attempt, reference: "ref-123", status: "sending")
  end

  let(:reference) { "ref-123" }
  let(:status) { "delivered" }

  subject(:status_update) { described_class.call(reference: reference, status: status) }

  it "updates the delivery attempt's status" do
    expect { status_update }
      .to change { delivery_attempt.reload.status }
      .to("delivered")
  end

  context "with a temporary failure" do
    let(:status) { "temporary-failure" }

    it "underscores statuses" do
      expect { status_update }
        .to change { delivery_attempt.reload.status }
        .to("temporary_failure")
    end

    it "retries sending the email" do
      expect(DeliveryRequestWorker).to receive(:perform_in)
        .with(15.minutes, delivery_attempt.email.id, :default)

      status_update
    end
  end

  context "with a permanent failure" do
    let(:status) { "permanent-failure" }

    it "unsubscribes the subscriber" do
      create(:subscriber, address: delivery_attempt.email.address)

      expect { status_update }
        .to change { Subscriber.last.address }
        .to(nil)
    end
  end

  context "with a missing reference" do
    let(:reference) { "missing" }

    it "raises an error" do
      expect { status_update }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "with an unknown status" do
    let(:status) { "unknown" }

    it "raises an error" do
      expect { status_update }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end

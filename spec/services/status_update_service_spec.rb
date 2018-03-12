RSpec.describe StatusUpdateService do
  let(:reference) { "b6589b2b-8f8e-457b-9ddf-237b62438ad1" }

  let!(:delivery_attempt) do
    create(:delivery_attempt, id: reference, status: "sending")
  end

  let(:status) { "delivered" }
  let(:completed_at) { Time.parse("2017-05-14T12:15:30.000000Z") }
  let(:sent_at) { Time.parse("2017-05-14T12:15:30.000000Z") }

  subject(:status_update) { described_class.call(reference: reference, status: status, completed_at: completed_at, sent_at: sent_at) }

  it "updates the delivery attempt's status" do
    expect { status_update }
      .to change { delivery_attempt.reload.status }
      .to("delivered")
  end

  it "updates the completed_at field" do
    expect { status_update }
      .to change { delivery_attempt.reload.completed_at }
      .to(completed_at)
  end

  it "updates the sent_at field on delivery" do
    expect { status_update }
      .to change { delivery_attempt.reload.sent_at }
      .to(sent_at)
  end

  it "updates the emails finished_sending_at timestamp" do
    expect { status_update }
      .to change { delivery_attempt.reload.email.finished_sending_at }
      .from(nil)
      .to(sent_at)
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

    it "does not update the emails finished_sending_at timestamp" do
      expect { status_update }
        .to_not(change { delivery_attempt.reload.email.finished_sending_at })
    end
  end

  context "with a permanent failure" do
    let(:status) { "permanent-failure" }

    it "deactivates the subscriber" do
      create(:subscriber, address: delivery_attempt.email.address)

      expect { status_update }
        .to change { Subscriber.last.deactivated? }
        .from(false)
        .to(true)
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
      expect { status_update }
        .to raise_error(StatusUpdateService::DeliveryAttemptInvalidStatusError)
    end
  end

  context "when the delivery attempt already has a non waiting status" do
    before do
      delivery_attempt.update!(status: "delivered")
    end

    it "raises an error" do
      expect { status_update }
        .to raise_error(StatusUpdateService::DeliveryAttemptStatusConflictError)
    end
  end
end

RSpec.describe StatusUpdateService do
  let!(:delivery_attempt) do
    create(:delivery_attempt, reference: "ref-123", status: "sending")
  end

  let(:args) do
    { reference: "ref-123", status: "delivered" }
  end

  subject { described_class.new(**args) }

  it "updates the delivery attempt's status" do
    expect { subject.call }
      .to change { delivery_attempt.reload.status }
      .to("delivered")
  end

  it "underscores statuses" do
    args[:status] = "temporary-failure"

    expect { subject.call }
      .to change { delivery_attempt.reload.status }
      .to("temporary_failure")
  end

  it "raises an error if the delivery attempt doesn't exist" do
    args[:reference] = "missing"

    expect { subject.call }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it "raises an error if the status isn't recognised" do
    args[:status] = "unknown"

    expect { subject.call }
      .to raise_error(ArgumentError)
  end
end

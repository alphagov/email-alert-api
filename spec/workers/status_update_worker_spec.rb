require "rails_helper"

RSpec.describe StatusUpdateWorker do
  let!(:delivery_attempt) do
    create(:delivery_attempt, reference: "ref-123", status: "sending")
  end

  let(:args) do
    { reference: "ref-123", status: "delivered" }
  end

  it "updates the delivery attempt's status" do
    expect { subject.perform(**args) }
      .to change { delivery_attempt.reload.status }
      .to("delivered")
  end

  it "underscores statuses" do
    expect { subject.perform(**args.merge(status: "temporary-failure")) }
      .to change { delivery_attempt.reload.status }
      .to("temporary_failure")
  end

  it "raises an error if the delivery attempt doesn't exist" do
    expect { subject.perform(**args.merge(reference: "missing")) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it "raises an error if the status isn't recognised" do
    expect { subject.perform(**args.merge(status: "unknown")) }
      .to raise_error(ArgumentError)
  end
end

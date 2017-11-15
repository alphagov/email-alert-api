require "rails_helper"

RSpec.describe Healthcheck::StatusUpdateHealthcheck do
  def create_delivery_attempt(status, updated, email = create(:email))
    create(:delivery_attempt, status: status, updated_at: updated, email: email)
  end

  context "when delivery attempts haven't received status updates" do
    context "in less than 72 hours" do
      before { create_delivery_attempt(:sending, 71.hours.ago) }
      specify { expect(subject.status).to eq(:ok) }
    end

    context "in more than 72 hours" do
      before { create_delivery_attempt(:sending, 73.hours.ago) }
      specify { expect(subject.status).to eq(:warning) }
    end

    context "in more than 74 hours" do
      before { create_delivery_attempt(:sending, 75.hours.ago) }
      specify { expect(subject.status).to eq(:critical) }
    end
  end

  it "builds in some tolerance while the queue is being processed" do
    create_delivery_attempt(:sending, (72.hours + 5.minutes).ago)
    expect(subject.status).to eq(:ok)
  end

  it "ignores delivery attempts that are superseded by newer ones" do
    email = FactoryGirl.create(:email)

    create_delivery_attempt(:sending, 73.hours.ago, email)
    create_delivery_attempt(:delivered, 5.hours.ago, email)

    expect(subject.status).to eq(:ok)
  end

  context "when delivery attempts have received status updates" do
    context "for a variety of times" do
      before do
        create_delivery_attempt(:delivered, 72.hours.ago)
        create_delivery_attempt(:delivered, 74.hours.ago)
        create_delivery_attempt(:delivered, 76.hours.ago)
      end

      specify { expect(subject.status).to eq(:ok) }
    end
  end
end

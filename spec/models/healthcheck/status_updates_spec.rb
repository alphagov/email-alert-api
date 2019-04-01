RSpec.describe Healthcheck::StatusUpdates do
  def create_delivery_attempt(status, created, email = create(:email))
    create(:delivery_attempt, status: status, created_at: created, email: email)
  end

  context "when a proportion of delivery attempts haven't received status updates" do
    context "at 5%" do
      before do
        create_delivery_attempt(:sending, 15.minutes.ago)
        19.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:ok) }
    end

    context "at 16.6%" do
      before do
        create_delivery_attempt(:sending, 15.minutes.ago)
        5.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end

      specify { expect(subject.status).to eq(:warning) }
    end

    context "at 25%" do
      before do
        create_delivery_attempt(:sending, 15.minutes.ago)
        3.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:critical) }
    end
  end

  it "builds in some tolerance while the queue is being processed" do
    create_delivery_attempt(:sending, 5.minutes.ago)
    expect(subject.status).to eq(:ok)
  end

  describe "#details" do
    before do
      2.times { create_delivery_attempt(:sending, 15.minutes.ago) }
      4.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      4.times { create_delivery_attempt(:technical_failure, 15.minutes.ago) }
    end

    it "shows the value" do
      expect(subject.details.fetch(:value)).to eq(0.2)
    end
  end
end

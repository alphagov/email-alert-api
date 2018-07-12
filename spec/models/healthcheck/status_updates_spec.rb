RSpec.describe Healthcheck::StatusUpdates do
  def create_delivery_attempt(status, created, email = create(:email))
    create(:delivery_attempt, status: status, created_at: created, email: email)
  end

  context "when status update callbacks are not expected" do
    before do
      allow(subject).to receive(:expect_status_update_callbacks?).and_return(false)
      create_delivery_attempt(:sending, 30.minutes.ago)
    end
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when a proportion of delivery attempts haven't received status updates" do
    context "at 5%" do
      before do
        create_delivery_attempt(:sending, 15.minutes.ago)
        19.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:ok) }
    end

    context "at 10%" do
      before do
        create_delivery_attempt(:sending, 15.minutes.ago)
        9.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:warning) }
    end

    context "at 20%" do
      before do
        create_delivery_attempt(:sending, 15.minutes.ago)
        4.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
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

    it "shows the totals" do
      totals = subject.details.fetch(:totals)

      expect(totals.fetch("pending")).to eq(2)
      expect(totals.fetch("done")).to eq(8)
    end

    it "shows the proportions" do
      expect(subject.details.fetch(:pending)).to eq(0.2)
      expect(subject.details.fetch(:done)).to eq(0.8)
    end
  end
end

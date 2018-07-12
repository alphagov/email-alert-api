RSpec.describe Healthcheck::TechnicalFailures do
  def create_delivery_attempt(status, created, email = create(:email))
    create(:delivery_attempt, status: status, created_at: created, email: email)
  end

  context "when status update callbacks are not expected" do
    before do
      allow(subject).to receive(:expect_status_update_callbacks?).and_return(false)
      create_delivery_attempt(:technical_failure, 30.minutes.ago)
    end
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when there are no technical failures" do
    before { create_delivery_attempt(:delivered, 1.minute.ago) }
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when a proportion of delivery attempts are technical failures" do
    context "at 2%" do
      before do
        1.times { create_delivery_attempt(:technical_failure, 15.minutes.ago) }
        49.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:ok) }
    end

    context "at 5%" do
      before do
        1.times { create_delivery_attempt(:technical_failure, 15.minutes.ago) }
        19.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:warning) }
    end

    context "at 10%" do
      before do
        1.times { create_delivery_attempt(:technical_failure, 15.minutes.ago) }
        9.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:critical) }
    end
  end

  describe "#details" do
    before do
      2.times { create_delivery_attempt(:technical_failure, 15.minutes.ago) }
      4.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      4.times { create_delivery_attempt(:sending, 15.minutes.ago) }
    end

    it "shows the totals" do
      totals = subject.details.fetch(:totals)

      expect(totals.fetch("failing")).to eq(2)
      expect(totals.fetch("other")).to eq(8)
    end

    it "shows the proportions" do
      expect(subject.details.fetch(:failing)).to eq(0.2)
      expect(subject.details.fetch(:other)).to eq(0.8)
    end
  end
end

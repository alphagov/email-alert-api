RSpec.describe Healthcheck::InternalFailures do
  def create_delivery_attempt(status, created, email = create(:email))
    create(:delivery_attempt, status: status, created_at: created, email: email)
  end

  context "when there are no provider failures" do
    before { create_delivery_attempt(:delivered, 1.minute.ago) }
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when a proportion of delivery attempts are provider failures" do
    context "at 2%" do
      before do
        1.times { create_delivery_attempt(:internal_failure, 15.minutes.ago) }
        49.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:ok) }
    end

    context "at 5%" do
      before do
        1.times { create_delivery_attempt(:internal_failure, 15.minutes.ago) }
        19.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:warning) }
    end

    context "at 10%" do
      before do
        1.times { create_delivery_attempt(:internal_failure, 15.minutes.ago) }
        9.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      end
      specify { expect(subject.status).to eq(:critical) }
    end
  end

  describe "#details" do
    before do
      2.times { create_delivery_attempt(:internal_failure, 15.minutes.ago) }
      4.times { create_delivery_attempt(:delivered, 15.minutes.ago) }
      4.times { create_delivery_attempt(:sending, 15.minutes.ago) }
    end

    it "shows the value" do
      expect(subject.details.fetch(:value)).to eq(0.2)
    end
  end
end

RSpec.describe DeliveryAttempt, type: :model do
  describe ".finished_sending_at" do
    subject { delivery_attempt.finished_sending_at }

    context "when email is sent" do
      let(:delivery_attempt) { build(:delivered_delivery_attempt) }
      it { is_expected.to eq delivery_attempt.sent_at }
    end

    context "when email failed" do
      let(:delivery_attempt) { build(:undeliverable_failure_delivery_attempt) }
      it { is_expected.to eq delivery_attempt.completed_at }
    end

    context "when email is sending" do
      let(:delivery_attempt) { build(:sending_delivery_attempt) }
      it { is_expected.to be_nil }
    end
  end
end

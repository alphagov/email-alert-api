RSpec.describe Healthcheck::RetrySize do
  let(:sidekiq_stats) { double(retry_size: size) }
  before { allow(Sidekiq::Stats).to receive(:new).and_return(sidekiq_stats) }

  context "when there aren't many retries" do
    let(:size) { 2 }
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when the warning threshold is reached" do
    let(:size) { 40005 }
    specify { expect(subject.status).to eq(:warning) }
  end

  context "when the critical threshold is reached" do
    let(:size) { 50010 }
    specify { expect(subject.status).to eq(:critical) }
  end

  describe "#details" do
    let(:size) { 3 }

    it "returns the number of retries" do
      expect(subject.details.fetch(:value)).to eq(3)
    end
  end
end

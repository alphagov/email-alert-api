RSpec.describe Healthcheck::QueueSize do
  let(:sidekiq_stats) { double(queues: { default: size }) }
  before { allow(Sidekiq::Stats).to receive(:new).and_return(sidekiq_stats) }

  context "when there aren't many jobs" do
    let(:size) { 1 }
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when the warning threshold is reached" do
    let(:size) { 80000 }
    specify { expect(subject.status).to eq(:warning) }
  end

  context "when the critical threshold is reached" do
    let(:size) { 200000 }
    specify { expect(subject.status).to eq(:critical) }
  end

  describe "#details" do
    let(:size) { 3 }

    it "returns a hash of the queues and their sizes" do
      expect(subject.details.fetch(:queues)).to match(default: hash_including(value: 3))
    end
  end
end

RSpec.describe Healthcheck::QueueSize do
  before { allow(subject).to receive(:queue_sizes).and_return [size] }

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
    let(:queues) { { default: size } }

    it "returns a hash of the queues and their sizes" do
      allow(subject).to receive(:queues).and_return(queues)
      expect(subject.details).to eq(queues: queues)
    end
  end
end

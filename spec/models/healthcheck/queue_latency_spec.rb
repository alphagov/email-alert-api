RSpec.describe Healthcheck::QueueLatency do
  let(:delivery_immediate_high_latency) { 0 }
  let(:delivery_immediate_latency) { 0 }
  let(:delivery_digest_latency) { 0 }

  before do
    allow(subject).to receive(:latency_for).with(:delivery_immediate_high).and_return(delivery_immediate_high_latency)
    allow(subject).to receive(:latency_for).with(:delivery_immediate).and_return(delivery_immediate_latency)
    allow(subject).to receive(:latency_for).with(:delivery_digest).and_return(delivery_digest_latency)
  end

  shared_examples "an ok healthcheck" do
    specify { expect(subject.status).to eq(:ok) }
  end

  shared_examples "a warning healthcheck" do
    specify { expect(subject.status).to eq(:warning) }
  end

  shared_examples "a critical healthcheck" do
    specify { expect(subject.status).to eq(:critical) }
  end

  context "when the delivery_immediate_high queue latency is critical" do
    let(:delivery_immediate_high_latency) { 10.minutes.to_i }
    it_behaves_like "a critical healthcheck"
  end

  context "when the delivery_immediate_high queue latency is warning" do
    let(:delivery_immediate_high_latency) { 3.minutes.to_i }
    it_behaves_like "a warning healthcheck"
  end

  context "when the delivery_immediate_high queue latency is ok" do
    let(:delivery_immediate_high_latency) { 1.minutes.to_i }
    it_behaves_like "an ok healthcheck"
  end

  context "when the delivery_immediate queue latency is critical" do
    let(:delivery_immediate_latency) { 10.minutes.to_i }
    it_behaves_like "a critical healthcheck"
  end

  context "when the delivery_immediate queue latency is warning" do
    let(:delivery_immediate_latency) { 3.minutes.to_i }
    it_behaves_like "a warning healthcheck"
  end

  context "when the delivery_immediate queue latency is ok" do
    let(:delivery_immediate_latency) { 1.minutes.to_i }
    it_behaves_like "an ok healthcheck"
  end

  context "when the delivery_digest queue latency is critical" do
    let(:delivery_digest_latency) { 95.minutes.to_i }
    it_behaves_like "a critical healthcheck"
  end

  context "when the delivery_digest queue latency is warning" do
    let(:delivery_digest_latency) { 65.minutes.to_i }
    it_behaves_like "a warning healthcheck"
  end

  context "when the delivery_digest queue latency is ok" do
    let(:delivery_digest_latency) { 10.minutes.to_i }
    it_behaves_like "an ok healthcheck"
  end
end

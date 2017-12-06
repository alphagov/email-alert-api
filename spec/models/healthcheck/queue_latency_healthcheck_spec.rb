require "rails_helper"

RSpec.describe Healthcheck::QueueLatencyHealthcheck do
  before { allow(subject).to receive(:queue_latencies).and_return [latency] }

  context "when it is quick to respond" do
    let(:latency) { 2 }
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when the warning threshold is reached" do
    let(:latency) { 5 }
    specify { expect(subject.status).to eq(:warning) }
  end

  context "when the critical threshold is reached" do
    let(:latency) { 500 }
    specify { expect(subject.status).to eq(:critical) }
  end
end

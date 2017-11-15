require "rails_helper"

RSpec.describe Healthcheck::RedisHealthcheck do
  context "when redis is available" do
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when redis is not available" do
    before { allow(Sidekiq).to receive(:redis_info).and_return(false) }
    specify { expect(subject.status).to eq(:critical) }
  end
end

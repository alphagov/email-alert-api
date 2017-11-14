require "rails_helper"

RSpec.describe Healthcheck::DatabaseHealthcheck do
  let(:db) { ActiveRecord::Base }

  context "when the database is connected" do
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when the database is not connected" do
    before { allow(db).to receive(:connected?).and_return(false) }
    specify { expect(subject.status).to eq(:critical) }
  end
end

RSpec.describe Healthcheck do
  let(:critical) do
    double(:healthcheck, name: :foo, status: :critical, details: {})
  end

  let(:warning) do
    double(:healthcheck, name: :bar, status: :warning, details: { errors: 7 })
  end

  let(:ok) do
    double(:healthcheck, name: :baz, status: :ok, details: { https: true })
  end

  before { allow(subject).to receive(:all).and_return(healthchecks) }

  context "when one of the checks is critical" do
    let(:healthchecks) { [warning, critical, ok] }
    specify { expect(subject.status).to eq(:critical) }
  end

  context "when no checks are critical but one is warning" do
    let(:healthchecks) { [ok, ok, warning] }
    specify { expect(subject.status).to eq(:warning) }
  end

  context "when all the checks are ok" do
    let(:healthchecks) { [ok, ok, ok] }
    specify { expect(subject.status).to eq(:ok) }
  end

  describe "#details" do
    let(:healthchecks) { [critical, warning, ok] }

    it "returns a hash containing statuses and details for the checks" do
      expect(subject.details).to eq(
        checks: {
          foo: { status: :critical },
          bar: { status: :warning, errors: 7 },
          baz: { status: :ok, https: true },
        },
      )
    end
  end
end

RSpec.describe HashDigest do
  describe ".generate" do
    subject { described_class.new(input).generate }
    let(:input) { {} }

    it "returns nil when given an empty hash" do
      expect(subject).to be_nil
    end

    context "when a hash is provided" do
      let(:input) do
        {
          a: 1, b: 2, aircraft_type: %w(plane helicopter),
          c: 3, d: 4, boat_type: %w(boat ship)
        }
      end

      it "returns a digest for a hash" do
        expect(subject).to eq("ee38bab7cf3dcfa3c0181cb26ad2bc25f006ca62fa030a81dc2b0ac353b4bddb")
      end

      it "returns the same digest every time the input is provided" do
        digests = (1..3).map { described_class.new(input).generate }
        expect(digests.uniq.count).to eq 1
      end
    end

    it "returns the same digest regardless of hash structure" do
      first_input = {
        a: [1, 2, 3, 4], b: %w(a b c d),
        prior: 'one',
        nested_tags: {
          number: 2,
          deep_nest: { foo: 'bar' },
          more_tags: %w(more and more),
        }
      }
      second_input = {
        b: %w(a c b d), a: [1, 4, 3, 2],
        nested_tags: {
          more_tags: %w(more more and),
          number: 2,
          deep_nest: { foo: 'bar' },
        },
        prior: 'one'
      }
      first_output = described_class.new(first_input).generate
      second_output = described_class.new(second_input).generate
      expect(first_output).to eq(second_output)
    end
  end
end

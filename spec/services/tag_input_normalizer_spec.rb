require "spec_helper"

require "tag_input_normalizer"

RSpec.describe TagInputNormalizer do

  subject(:tag_normalizer) {
    TagInputNormalizer.new(
      service: service,
      context: context,
      tags: tags,
    )
  }

  let(:context) { double(:context) }
  let(:service) { double(:service, call: nil) }
  let(:tags) { {} }

  describe "#call" do
    context "when tag parameters are out of order (not normalized)" do
      let(:tags) {
        {
          "foo_tag" => [ "foo_value_3", "foo_value_1", "foo_value_2"],
          "bar_tag" => [ "bar_value_1", "bar_value_3", "bar_value_2"],
        }
      }

      let(:normalized_tags) {
        {
          "foo_tag" => [ "foo_value_1", "foo_value_2", "foo_value_3"],
          "bar_tag" => [ "bar_value_1", "bar_value_2", "bar_value_3"],
        }
      }

      it "sorts the tag values alphabetically for comparison" do
        tag_normalizer.call

        expect(service).to have_received(:call).with(
          context,
          tags: normalized_tags,
        )
      end
    end
  end
end

require "spec_helper"

require "tag_set"

RSpec.describe TagSet do
  subject(:tag_set) {
    TagSet.new(tag_hash)
  }

  let(:tag_hash) {
    {
      tag_name => [
        tag_value_2,
        tag_value_1,
      ],
    }
  }

  let(:sorted_tag_hash) {
    {
      tag_name => [
        tag_value_1,
        tag_value_2,
      ],
    }
  }

  let(:tag_name)    { "tag_name" }
  let(:tag_value_1) { "tag_value_1" }
  let(:tag_value_2) { "tag_value_2" }

  # #to_hash is an alias of #to_h
  describe "#to_hash" do
    it "sorts tag values" do
      expect(tag_set.to_hash).to eq(sorted_tag_hash)
    end
  end

  describe "#fetch" do
    it "delegates to the hash returning sorted values" do
      expect(tag_set.fetch(tag_name)).to eq(sorted_tag_hash.fetch(tag_name))
    end
  end
end

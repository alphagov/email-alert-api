require "spec_helper"

require "tags_param_validator"

RSpec.describe TagsParamValidator do
  subject(:validator) do
    TagsParamValidator.new(param)
  end

  context "given nil" do
    let(:param) { nil }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given a non hash" do
    let(:param) { "this is a string" }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given an empty hash" do
    let(:param) { {} }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given a hash with non string keys" do
    let(:param) {
      {
        "a string" => ["a value"],
        :a_symbol => ["another value"],
      }
    }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given a hash with non array values" do
    let(:param) {
      {
        "key" => "a bare string",
      }
    }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given a hash with empty array values" do
    let(:param) {
      {
        "key" => [],
      }
    }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given a hash with array values containing non strings" do
    let(:param) {
      {
        "key" => ["a string", :a_symbol],
      }
    }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given a hash with array values containing empty strings" do
    let(:param) {
      {
        "key" => ["non empty string", ""],
      }
    }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given a well-formed hash" do
    let(:param) {
      {
        "a string key" => ["a value"],
        "another key" => ["some", "more", "values"],
      }
    }

    it "should be valid" do
      expect(validator).to be_valid
    end
  end
end

require "spec_helper"

require "string_param_validator"

RSpec.describe StringParamValidator do
  subject(:validator) do
    StringParamValidator.new(param)
  end

  context "given nil" do
    let(:param) { nil }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given an empty string" do
    let(:param) { "" }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end

  context "given a non empty string" do
    let(:param) { "test value" }

    it "should be valid" do
      expect(validator).to be_valid
    end
  end

  context "given a non string" do
    let(:param) { [] }

    it "should not be valid" do
      expect(validator).not_to be_valid
    end
  end
end

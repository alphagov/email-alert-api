RSpec.describe AbsolutePathValidator do
  class AbsolutePathValidatable
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_accessor :path
    validates :path, absolute_path: true
  end

  subject(:model) { AbsolutePathValidatable.new }

  context "when an absolute path is provided" do
    before { model.path = "/test" }
    it { is_expected.to be_valid }
  end

  context "when a relative path is provided" do
    before { model.path = "test" }

    it "has an error" do
      expect(model.valid?).to be false
      expect(model.errors[:path]).to match(["must be an absolute path"])
    end
  end

  context "when an invalid URI is provided" do
    before { model.path = "bad URI" }

    it { is_expected.not_to be_valid }
  end

  context "when a full url is provided" do
    before { model.path = "https://example.com/test" }

    it { is_expected.not_to be_valid }
  end

  context "when a path with query string is provided" do
    before { model.path = "/test?test=this" }

    it { is_expected.to be_valid }
  end

  context "when a path with a fragment is provided" do
    before { model.path = "/test#fragment" }

    it { is_expected.to be_valid }
  end
end

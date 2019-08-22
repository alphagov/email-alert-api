RSpec.describe RootRelativeUrlValidator do
  class RootRelativeUrlValidatable
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_accessor :url
    validates :url, root_relative_url: true
  end

  subject(:model) { RootRelativeUrlValidatable.new }

  context "when an absolute path is provided" do
    before { model.url = "/test" }
    it { is_expected.to be_valid }
  end

  context "when a relative path is provided" do
    before { model.url = "test" }

    it "has an error" do
      expect(model.valid?).to be false
      expect(model.errors[:url]).to match(["must be a root-relative URL"])
    end
  end

  context "when an invalid URI is provided" do
    before { model.url = "bad URI" }

    it { is_expected.not_to be_valid }
  end

  context "when a full url is provided" do
    before { model.url = "https://example.com/test" }

    it { is_expected.not_to be_valid }
  end

  context "when a path with query string is provided" do
    before { model.url = "/test?test=this" }

    it { is_expected.to be_valid }
  end

  context "when a path with a fragment is provided" do
    before { model.url = "/test#fragment" }

    it { is_expected.to be_valid }
  end
end

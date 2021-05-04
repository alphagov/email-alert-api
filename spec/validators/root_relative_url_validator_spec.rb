RSpec.describe RootRelativeUrlValidator do
  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      include ActiveModel::Model

      attr_accessor :url

      validates :url, root_relative_url: true
    end
  end

  it "is valid for an absolute path" do
    expect(record_class.new(url: "/path")).to be_valid
  end

  it "is invalid for a relative path" do
    expect(record_class.new(url: "path")).to be_invalid
  end

  it "is invalid when a protocol-relative url is provided" do
    expect(record_class.new(url: "//example.com/test")).to be_invalid
  end

  it "is invalid for an invalid URI" do
    expect(record_class.new(url: "bad uri")).to be_invalid
  end
end

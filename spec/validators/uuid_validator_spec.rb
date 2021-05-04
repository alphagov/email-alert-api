RSpec.describe UuidValidator do
  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      include ActiveModel::Model

      attr_accessor :uuid

      validates :uuid, uuid: true
    end
  end

  it "is valid for a correctly formatted UUID" do
    expect(record_class.new(uuid: SecureRandom.uuid)).to be_valid
  end

  it "is invalid for a incorrectly formatted UUID" do
    expect(record_class.new(uuid: "not a UUID")).to be_invalid
  end
end

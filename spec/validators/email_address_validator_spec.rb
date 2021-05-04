RSpec.describe EmailAddressValidator do
  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      include ActiveModel::Model

      attr_accessor :email

      validates :email, email_address: true
    end
  end

  it "is valid when a valid email is provided" do
    expect(record_class.new(email: "test@example.com")).to be_valid
  end

  it "is invalid when an invalid email is provided" do
    record = record_class.new(email: "bad email")
    expect(record).to be_invalid
    expect(record.errors[:email]).to match(["is not an email address"])
  end
end

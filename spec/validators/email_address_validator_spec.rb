RSpec.describe EmailAddressValidator do
  class EmailAddressValidatable
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_accessor :email
    validates :email, email_address: true
  end

  subject(:model) { EmailAddressValidatable.new }

  context "when a valid email is provided" do
    before { model.email = "test@example.com" }
    it { is_expected.to be_valid }
  end

  context "when an invalid email is provided" do
    before { model.email = "bad email" }

    it "has an error" do
      expect(model.valid?).to be false
      expect(model.errors[:email]).to match(["is not an email address"])
    end
  end
end

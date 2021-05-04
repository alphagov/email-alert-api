RSpec.describe UuidValidator do
  class UuidValidatable
    include ActiveModel::Validations
    include ActiveModel::Model

    attr_accessor :uuid

    validates :uuid, uuid: true
  end

  subject(:model) { UuidValidatable.new }

  context "when a valid UUID is provided" do
    before { model.uuid = SecureRandom.uuid }
    it { is_expected.to be_valid }
  end

  context "when an invalid UUID is provided" do
    before { model.uuid = "ThisIsNotAValidUUID" }

    it "has an error" do
      expect(model.valid?).to be false
      expect(model.errors[:uuid]).to match(["is not a valid UUID"])
    end
  end
end

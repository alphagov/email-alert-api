require "rails_helper"

RSpec.describe Subscription, type: :model do
  describe "validations" do
    subject { FactoryGirl.build(:subscription) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end
  end
end

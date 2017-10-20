require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "validations" do
    subject { FactoryGirl.create(:notification) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end
  end
end

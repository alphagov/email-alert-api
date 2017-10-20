require "rails_helper"

RSpec.describe Subscription, type: :model do
  describe "validations" do
    subject { FactoryGirl.build(:subscription) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "must be unique between subscriber and subscriber lists" do
      FactoryGirl.create(
        :subscription,
        subscriber: subject.subscriber,
        subscriber_list: subject.subscriber_list
      )

      expect(subject).to be_invalid
    end
  end
end

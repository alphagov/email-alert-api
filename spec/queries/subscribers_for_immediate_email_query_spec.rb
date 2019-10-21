require "rails_helper"

RSpec.describe SubscribersForImmediateEmailQuery do
  context "when passed a content change" do
    it "returns Subscriber objects that have an email-less SubscriptionContent" do
      subscription_content = create(:subscription_content, email: nil)
      filter_hash = { content_change_id: subscription_content.content_change_id }
      expect(described_class.call(filter_hash).count).to eq(1)
    end

    it "does not return Subscriber objects with email_id != nil" do
      subscription_content = create(:subscription_content, email: build(:email))
      filter_hash = { content_change_id: subscription_content.content_change_id }
      expect(described_class.call(filter_hash).count).to eq(0)
    end

    it "does not return Subscriber for nullified subscribers" do
      subscription = create(:subscription, subscriber: create(:subscriber, :nullified))
      subscription_content = create(:subscription_content, subscription: subscription)
      filter_hash = { content_change_id: subscription_content.content_change_id }
      expect(described_class.call(filter_hash).count).to eq(0)
    end

    it "does not return Subscriber for deactivates subscribers" do
      subscription = create(:subscription, subscriber: create(:subscriber, :deactivated))
      subscription_content = create(:subscription_content, subscription: subscription)
      filter_hash = { content_change_id: subscription_content.content_change_id }
      expect(described_class.call(filter_hash).count).to eq(0)
    end

    it "returns one record per subscriber" do
      content_change = create(:content_change)
      subscriber = create(:subscriber)
      create(:subscription_content, subscription: create(:subscription, subscriber: subscriber), content_change: content_change)
      create(:subscription_content, subscription: create(:subscription, subscriber: subscriber), content_change: content_change)

      create(:subscription_content, email: create(:email), subscription: create(:subscription, subscriber: subscriber), content_change: content_change)

      content_change = ContentChange.last
      create(:subscription_content, subscription: create(:subscription, subscriber: subscriber), content_change: content_change)
      create(:subscription_content, subscription: create(:subscription, subscriber: subscriber), content_change: content_change)

      filter_hash = { content_change_id: content_change.id }
      expect(described_class.call(filter_hash).count).to eq(1)
    end

    it "only returns subscribers for that content change" do
      content_change_one = create(:content_change)
      content_change_two = create(:content_change)
      subscriber_one = create(:subscriber)
      subscriber_two = create(:subscriber)
      create(:subscription_content, subscription: create(:subscription, subscriber: subscriber_one), content_change: content_change_one)
      create(:subscription_content, subscription: create(:subscription, subscriber: subscriber_two), content_change: content_change_two)
      filter_hash = { content_change_id: content_change_one.id }
      expect(described_class.call(filter_hash)).to eq([subscriber_one])
    end
  end
end

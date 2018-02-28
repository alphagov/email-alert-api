require "rails_helper"

RSpec.describe SubscribersForImmediateEmailQuery do
  it "returns Subscriber objects that have an email-less SubscriptionContent" do
    create(:subscription_content, email: nil)
    expect(described_class.call.count).to eq(1)
  end

  it "does not return Subscriber objects with email_id != nil" do
    create(:subscription_content, email: build(:email))
    expect(described_class.call.count).to eq(0)
  end

  it "does not return Subscriber for nullified subscribers" do
    create(:subscription_content, subscription: create(:subscription, subscriber: create(:subscriber, :nullified)))
    expect(described_class.call.count).to eq(0)
  end

  it "does not return Subscriber for deactivates subscribers" do
    create(:subscription_content, subscription: create(:subscription, subscriber: create(:subscriber, :deactivated)))
    expect(described_class.call.count).to eq(0)
  end

  it "returns one record per subscriber" do
    create(:subscription_content, subscription: create(:subscription, subscriber: subscriber = create(:subscriber)))
    create(:subscription_content, subscription: create(:subscription, subscriber: subscriber))

    create(:subscription_content, email: create(:email), subscription: create(:subscription, subscriber: subscriber))

    content_change = ContentChange.last
    create(:subscription_content, subscription: create(:subscription, subscriber: subscriber), content_change: content_change)
    create(:subscription_content, subscription: create(:subscription, subscriber: subscriber), content_change: content_change)

    expect(described_class.call.count).to eq(1)
  end
end

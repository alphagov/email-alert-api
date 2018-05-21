require "rails_helper"

RSpec.describe UnprocessedSubscriptionContentsBySubscriberQuery do
  let!(:subscriber_one) { create(:subscriber) }
  let!(:subscriber_two) { create(:subscriber) }
  let!(:subscriber_three) { create(:subscriber) }
  let(:content_change_one) { create(:content_change) }
  let(:content_change_two) { create(:content_change) }

  before do
    create(:subscription_content, subscription: create(:subscription, subscriber: subscriber_one), content_change: content_change_one)
    create(:subscription_content, subscription: create(:subscription, subscriber: subscriber_one), content_change: content_change_one)
    create(:subscription_content, subscription: create(:subscription, subscriber: subscriber_one), content_change: content_change_two)
    create(:subscription_content, subscription: create(:subscription, subscriber: subscriber_three), content_change: content_change_two)
  end

  subject { described_class.call([subscriber_one.id, subscriber_two.id]) }

  it "returns a hash keyed by subscriber_id" do
    expect(subject.keys).to match_array([subscriber_one.id])
  end

  it "creates a hash keyed by content_change_id per subscriber key" do
    expect(subject[subscriber_one.id].keys).to match_array(ContentChange.pluck(:id))
  end

  it "creates an array of subscription contents at each content change key" do
    expect(subject[subscriber_one.id][content_change_one.id])
      .to match_array(SubscriptionContent.where(content_change: content_change_one))
  end

  it "only returns the subscribers requested" do
    expect(subject[subscriber_three.id]).to be_nil
  end
end

require "rails_helper"

RSpec.describe UnprocessedSubscriptionContentsBySubscriberQuery do
  let!(:subscriber_one) { create(:subscriber) }
  let!(:subscriber_two) { create(:subscriber) }
  let!(:subscriber_three) { create(:subscriber) }

  let!(:subscription_content_one) do
    create(
      :subscription_content,
      subscription: create(:subscription, subscriber: subscriber_one),
    )
  end

  let!(:subscription_content_two) do
    create(
      :subscription_content,
      :with_message,
      subscription: create(:subscription, subscriber: subscriber_one),
    )
  end

  let!(:subscription_content_three) do
    create(
      :subscription_content,
      subscription: create(:subscription, subscriber: subscriber_two),
    )
  end

  subject(:result) { described_class.call([subscriber_one.id, subscriber_two.id]) }

  it "returns a hash of subscription contents for subscription contents" do
    expected = {
      subscriber_one.id => match_array([subscription_content_one, subscription_content_two]),
      subscriber_two.id => match_array([subscription_content_three]),
    }

    expect(described_class.call([subscriber_one.id, subscriber_two.id]))
      .to match(expected)
  end
end

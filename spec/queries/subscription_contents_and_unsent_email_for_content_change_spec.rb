RSpec.describe SubscriptionContentsAndUnsentEmailForContentChange do
  let(:relevant_content_change) { create(:content_change) }
  let!(:subscription_content_one) {
    create(
      :subscription_content,
      content_change: relevant_content_change,
      email: build(:email),
    )
  }
  let!(:subscription_content_two) {
    create(
      :subscription_content,
      content_change: relevant_content_change,
      email: build(:email),
    )
  }
  let!(:subscription_content_not_relevant) {
    create(
      :subscription_content,
      content_change: build(:content_change),
      email: build(:email),
    )
  }

  it "returns only the subscription content relevant to the content change" do
    expected_result_set = described_class.call(relevant_content_change.id)
    expect(expected_result_set).to match_array([subscription_content_one, subscription_content_two])
  end

  it "does not return non-relevant subscription content" do
    expected_ids = described_class.call(relevant_content_change.id).pluck(:id)
    expect(expected_ids).not_to include(subscription_content_not_relevant.id)
  end
end

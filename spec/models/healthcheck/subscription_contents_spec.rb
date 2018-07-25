RSpec.describe Healthcheck::SubscriptionContents do
  shared_examples "an ok healthcheck" do
    specify { expect(subject.status).to eq(:ok) }
  end

  shared_examples "a warning healthcheck" do
    specify { expect(subject.status).to eq(:warning) }
  end

  shared_examples "a critical healthcheck" do
    specify { expect(subject.status).to eq(:critical) }
  end

  context "when a subscription content was created 10 second ago" do
    before do
      create(:subscription_content, created_at: 10.seconds.ago)
    end

    it_behaves_like "an ok healthcheck"
  end

  context "when a subscription content was created 2 minutes ago" do
    before do
      create(:subscription_content, created_at: 2.minutes.ago)
    end

    it_behaves_like "a warning healthcheck"
  end

  context "when a subscription content was created 5 minutes ago" do
    before do
      create(:subscription_content, created_at: 5.minutes.ago)
    end

    it_behaves_like "a critical healthcheck"
  end
end

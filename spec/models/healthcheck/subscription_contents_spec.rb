RSpec.describe Healthcheck::SubscriptionContents do
  context "when scheduled publishing" do
    shared_examples "an ok healthcheck" do
      specify { expect(subject.status).to eq(:ok) }
      specify { expect(subject.message).to match(/0 created over 3000 seconds ago/) }
    end

    shared_examples "a warning healthcheck" do
      specify { expect(subject.status).to eq(:warning) }
      specify { expect(subject.message).to match(/1 created over 2100 seconds ago/) }
    end

    shared_examples "a critical healthcheck" do
      specify { expect(subject.status).to eq(:critical) }
      specify { expect(subject.message).to match(/1 created over 3000 seconds ago/) }
    end

    shared_examples "tests all three states" do
      context "when a subscription content was created 15 minutes ago" do
        before { create(:subscription_content, created_at: 15.minutes.ago) }
        it_behaves_like "an ok healthcheck"
      end

      context "when a subscription content was created over 35 minutes ago" do
        before { create(:subscription_content, created_at: 36.minutes.ago) }
        it_behaves_like "a warning healthcheck"
      end

      context "when a subscription content was created over 50 minutes ago" do
        before { create(:subscription_content, created_at: 51.minutes.ago) }
        it_behaves_like "a critical healthcheck"
      end
    end

    context "between 09:30 and 11:00" do
      around do |example|
        Timecop.freeze("10:00") { example.run }
      end

      include_examples "tests all three states"
    end

    context "between 12:30 and 13:30" do
      around do |example|
        Timecop.freeze("13:00") { example.run }
      end

      include_examples "tests all three states"
    end
  end

  context "when not scheduled publishing time" do
    shared_examples "an ok healthcheck" do
      specify { expect(subject.status).to eq(:ok) }
      specify { expect(subject.message).to match(/0 created over 900 seconds ago/) }
    end

    shared_examples "a warning healthcheck" do
      specify { expect(subject.status).to eq(:warning) }
      specify { expect(subject.message).to match(/1 created over 600 seconds ago/) }
    end

    shared_examples "a critical healthcheck" do
      specify { expect(subject.status).to eq(:critical) }
      specify { expect(subject.message).to match(/1 created over 900 seconds ago/) }
    end

    around do |example|
      Timecop.freeze("12:00") { example.run }
    end

    context "when a subscription content was created 10 seconds ago" do
      before { create(:subscription_content, created_at: 10.seconds.ago) }
      it_behaves_like "an ok healthcheck"
    end

    context "when a subscription content was created over 10 minutes ago" do
      before { create(:subscription_content, created_at: 11.minutes.ago) }
      it_behaves_like "a warning healthcheck"
    end

    context "when a subscription content was created over 20 minutes ago" do
      before { create(:subscription_content, created_at: 21.minutes.ago) }
      it_behaves_like "a critical healthcheck"
    end
  end
end

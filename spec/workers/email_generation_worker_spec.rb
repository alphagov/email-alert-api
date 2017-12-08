require "rails_helper"

RSpec.describe EmailGenerationWorker do
  let(:priority) { :low }

  describe ".perform" do
    context "with a subscription content" do
      let(:content_change) { create(:content_change, public_updated_at: DateTime.parse("2017/01/01 09:00")) }
      let(:subscription_content) { create(:subscription_content, content_change: content_change) }

      def perform_with_fake_sidekiq
        Sidekiq::Testing.fake! do
          DeliveryRequestWorker.jobs.clear
          described_class.new.perform(subscription_content.id, priority)
        end
      end

      it "should create an email" do
        expect {
          perform_with_fake_sidekiq
        }
          .to change { Email.count }
          .from(0)
          .to(1)
      end

      it "should associate the subscription content with the email" do
        perform_with_fake_sidekiq
        expect(subscription_content.reload.email).to_not be_nil
      end

      it "should queue a delivery email job" do
        perform_with_fake_sidekiq
        expect(DeliveryRequestWorker.jobs.size).to eq(1)
      end
    end
  end
end

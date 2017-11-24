require "rails_helper"

RSpec.describe EmailGenerationWorker do
  let(:priority) { :low }

  describe ".perform" do
    context "with a subscription content" do
      let(:content_change) { create(:content_change, public_updated_at: DateTime.parse("2017/01/01 09:00")) }
      let(:subscription_content) { create(:subscription_content, content_change: content_change) }

      before do
        Sidekiq::Testing.fake! do
          DeliveryRequestWorker.jobs.clear
          described_class.new.perform(subscription_content_id: subscription_content.id, priority: priority)
        end
      end


      it "should create an email" do
        expected_params = {
          title: "title",
          change_note: "change note",
          description: "description",
          base_path: "government/base_path",
        }

        expect(Email).to receive(:create_from_params!)
          .with(hash_including(expected_params))
      end

      it "should associate the subscription content with the email" do
        expect(subscription_content.reload.email).to_not be_nil
      end

      it "should queue a delivery email job" do
        expect(DeliveryRequestWorker.jobs.size).to eq(1)
      end
    end
  end
end

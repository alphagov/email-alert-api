require "rails_helper"

RSpec.describe EmailGenerationWorker do
  let(:priority) { :low }

  describe ".perform" do
    context "with a subscription content" do
      let(:content_change) { create(:content_change, public_updated_at: DateTime.parse("2017/01/01 09:00")) }
      let(:subscription_content) { create(:subscription_content, content_change: content_change) }

      before do
        Sidekiq::Testing.fake! do
          DeliverEmailWorker.jobs.clear
          described_class.new.perform(subscription_content_id: subscription_content.id, priority: priority)
        end
      end

      it "should create an email" do
        expect(Email.count).to eq(1)

        email = Email.first
        expect(email.address).to eq(subscription_content.subscription.subscriber.address)
        expect(email.subject).to eq("GOV.UK Update - title")
        expect(email.body).to eq("change note: description.\n\nhttp://www.dev.gov.ukgovernment/base_path\nUpdated on 09:00 am, 1 January 2017\n\nUnsubscribe from title - http://www.dev.gov.uk/email/token/unsubscribe\n")
      end

      it "should associate the subscription content with the email" do
        expect(subscription_content.reload.email).to_not be_nil
      end

      it "should queue a delivery email job" do
        expect(DeliverEmailWorker.jobs.size).to eq(1)
      end
    end
  end
end

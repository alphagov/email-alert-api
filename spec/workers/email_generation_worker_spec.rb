RSpec.describe EmailGenerationWorker do
  describe ".perform" do
    def perform_with_fake_sidekiq
      Sidekiq::Testing.fake! do
        DeliveryRequestWorker.jobs.clear
        described_class.new.perform
      end
    end

    context "with a subscription content" do
      let!(:subscription_content) { create(:subscription_content) }

      before do
        create(:subscription_content, email: create(:email))
        create(:subscription_content, subscription: create(:subscription, subscriber: create(:subscriber, address: nil)))
      end

      it "should create an email" do
        expect {
          perform_with_fake_sidekiq
        }
          .to change { Email.count }
          .from(1)
          .to(2)
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

    context "with many subscription contents running concurrently" do
      before do
        100.times do
          create(:subscription_content)
        end
      end

      def run_worker
        Sidekiq::Testing.fake! { described_class.new.perform }
      end

      def run_worker_threads
        Rails.application.eager_load! # needed as autoload is not thread safe

        3.times
          .map { Thread.new { run_worker } }
          .each(&:join)
      end

      it "will raise a stale object exception" do
        expect { run_worker_threads }.to raise_error(ActiveRecord::StaleObjectError)
      end
    end
  end
end

RSpec.describe SendEmailJob do
  let(:rate_limiter) do
    instance_double(Ratelimit, exceeded?: false, add: nil)
  end

  before do
    allow(Services).to receive(:rate_limiter).and_return(rate_limiter)
  end

  describe "#perform" do
    let(:email) { create(:email) }
    let(:queue) { "default" }

    it "delegates sending the email to SendEmailService" do
      expect(SendEmailService)
        .to receive(:call)
        .with(email:, metrics: {})
      described_class.new.perform(email.id, {}, queue)
    end

    it "parses scalar metrics and passes them to SendEmailService" do
      freeze_time do
        expect(SendEmailService)
          .to receive(:call)
          .with(email:, metrics: { content_change_created_at: Time.zone.now })

        described_class.new.perform(
          email.id,
          { "content_change_created_at" => Time.zone.now.iso8601 },
          queue,
        )
      end
    end

    it "increments the rate limiter" do
      expect(rate_limiter).to receive(:add).with("requests")
      described_class.new.perform(email.id, {}, queue)
    end

    it "exits early when there isn't a pending email for the id" do
      non_pending_email = create(:email, status: :failed)
      expect(SendEmailService).not_to receive(:call)
      described_class.new.perform(non_pending_email.id, {}, queue)
    end

    context "when rate limit is exceeded" do
      around { |example| Sidekiq::Testing.fake! { example.run } }
      before { allow(rate_limiter).to receive(:exceeded?).and_return(true) }

      it "requeues the job for 5 minutes time" do
        freeze_time do
          described_class.new.perform(email.id, {}, queue)

          job = {
            "args" => array_including(email.id, {}, queue),
            "at" => 5.minutes.from_now.to_f,
            "class" => described_class.name,
          }
          expect(Sidekiq::Queues[queue]).to include(hash_including(job))
        end
      end

      it "doesn't attempt to send the email" do
        expect(SendEmailService).not_to receive(:call)
        described_class.new.perform(email.id, {}, queue)
      end
    end
  end
end

RSpec.describe DeliveryRequestWorker do
  let(:rate_limiter) do
    instance_double(Ratelimit, exceeded?: false, add: nil)
  end

  before do
    allow(Services).to receive(:rate_limiter).and_return(rate_limiter)
  end

  describe "#perform" do
    let(:email) { create(:email) }
    let(:queue) { "default" }

    it "delegates sending the email to DeliveryRequestService" do
      expect(DeliveryRequestService)
        .to receive(:call)
        .with(email: email, metrics: {})
      described_class.new.perform(email.id, {}, queue)
    end

    it "parses scalar metrics and passes them to DeliveryRequestService" do
      freeze_time do
        expect(DeliveryRequestService)
          .to receive(:call)
          .with(email: email, metrics: { content_change_created_at: Time.zone.now })

        described_class.new.perform(
          email.id,
          { "content_change_created_at" => Time.zone.now.iso8601 },
          queue,
        )
      end
    end

    it "increments the rate limiter" do
      expect(rate_limiter).to receive(:add).with("delivery_request")
      described_class.new.perform(email.id, {}, queue)
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
        expect(DeliveryRequestService).not_to receive(:call)
        described_class.new.perform(email.id, {}, queue)
      end
    end
  end

  describe ".sidekiq_retries_exhausted_block" do
    let(:email) { create(:email) }
    let(:sidekiq_message) do
      {
        "args" => [email.id, {}],
        "queue" => "delivery_immediate_high",
        "class" => described_class.name,
      }
    end

    it "marks the job as failed" do
      delivery_attempt = create(:provider_communication_failure_delivery_attempt,
                                email: email)
      described_class.sidekiq_retries_exhausted_block.call(sidekiq_message)
      expect(email.reload).to have_attributes(
        status: "failed",
        finished_sending_at: delivery_attempt.reload.finished_sending_at,
      )
    end

    context "when there isn't a delivery attempt" do
      it "sets the email finished_sending_at time to current time" do
        freeze_time do
          described_class.sidekiq_retries_exhausted_block.call(sidekiq_message)
          expect(email.reload).to have_attributes(
            status: "failed",
            finished_sending_at: Time.zone.now,
          )
        end
      end
    end
  end

  describe ".perform_async_in_queue" do
    let(:email) { double(id: 0) }

    before do
      Sidekiq::Testing.fake! do
        described_class.perform_async_in_queue(email.id, queue: queue)
      end
    end

    context "with a delivery digest queue" do
      let(:queue) { "delivery_digest" }

      it "adds a worker to the correct queue" do
        expect(Sidekiq::Queues["delivery_digest"].size).to eq(1)
      end
    end

    context "with a delivery immediate queue" do
      let(:queue) { "delivery_immediate" }

      it "adds a worker to the correct queue" do
        expect(Sidekiq::Queues["delivery_immediate"].size).to eq(1)
      end
    end
  end
end

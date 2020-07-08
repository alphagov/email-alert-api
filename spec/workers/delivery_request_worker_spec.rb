RSpec.describe DeliveryRequestWorker do
  let(:rate_limiter) do
    instance_double(Ratelimit, exceeded?: false, add: nil)
  end

  before do
    Sidekiq::Worker.clear_all
    allow(Services).to receive(:rate_limiter).and_return(rate_limiter)
  end

  describe "#perform" do
    let(:email) { create(:email) }
    let(:queue) { "default" }

    it "delegates sending the email to DeliveryRequestService" do
      expect(DeliveryRequestService).to receive(:call).with(email: email)
      described_class.new.perform(email.id, queue)
    end

    it "increments the rate limiter" do
      expect(rate_limiter).to receive(:add).with("delivery_request")
      described_class.new.perform(email.id, queue)
    end

    context "when rate limit is exceeded" do
      it "raises a RatelimitExceededError" do
        allow(rate_limiter).to receive(:exceeded?).and_return(true)
        expect { described_class.new.perform(email.id, queue) }
          .to raise_error(described_class::RateLimitExceededError)
      end
    end
  end

  describe ".sidekiq_retries_exhausted_block" do
    around do |example|
      Sidekiq::Testing.fake! do
        freeze_time { example.run }
      end
    end

    let(:email) { create(:email) }
    let(:sidekiq_message) do
      {
        "args" => [email.id, "delivery_immediate_high"],
        "queue" => "delivery_immediate_high",
        "class" => described_class.name,
      }
    end

    it "retries the job in 5 minutes for a RatelimitExceededError" do
      described_class.sidekiq_retries_exhausted_block.call(
        sidekiq_message,
        described_class::RateLimitExceededError.new,
      )

      expect(DeliveryRequestWorker.jobs).to contain_exactly(
        hash_including(
          "queue" => "delivery_immediate_high",
          "args" => array_including(email.id, "delivery_immediate_high"),
          "at" => 5.minutes.from_now.to_f,
        ),
      )
    end

    it "doesn't do anything for other errors" do
      described_class.sidekiq_retries_exhausted_block.call(
        sidekiq_message,
        RuntimeError.new,
      )

      expect(DeliveryRequestWorker.jobs).to be_empty
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

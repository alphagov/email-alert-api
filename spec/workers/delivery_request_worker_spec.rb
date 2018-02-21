RSpec.describe DeliveryRequestWorker do
  let(:rate_limiter) { double(exceeded?: false, add: nil) }

  before do
    Sidekiq::Worker.clear_all
    allow(Services).to receive(:rate_limiter).and_return(rate_limiter)
  end

  describe ".perform" do
    let(:email) { create(:email) }
    let(:queue) { :default }

    context "with an email and a subscriber" do
      it "calls the DeliveryRequestService" do
        expect(DeliveryRequestService).to receive(:call).with(email: email)
        subject.perform(email.id, queue)
      end
    end

    context "with rate limit exceeded" do
      it "raises a RatelimitExceededError" do
        allow(rate_limiter).to receive(:exceeded?).and_return(true)
        expect {
          subject.perform(email.id, queue)
        }.to raise_error(RatelimitExceededError)
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

  describe "rate_limiter" do
    describe "rate_limit_threshold" do
      before do
        ENV["DELIVERY_REQUEST_THRESHOLD"] = nil
      end

      it "returns ENV['DELIVERY_REQUEST_THRESHOLD'] if set" do
        ENV["DELIVERY_REQUEST_THRESHOLD"] = "10"
        expect(subject.rate_limit_threshold).to eq(10)
      end

      it "is 21600 by default" do
        expect(subject.rate_limit_threshold).to eq(21600)
      end
    end

    describe "rate_limit_interval" do
      before do
        ENV["DELIVERY_REQUEST_INTERVAL"] = nil
      end

      it "returns ENV['DELIVERY_REQUEST_INTERVAL'] if set" do
        ENV["DELIVERY_REQUEST_INTERVAL"] = "20"
        expect(subject.rate_limit_interval).to eq(20)
      end

      it "is 60 by default" do
        expect(subject.rate_limit_interval).to eq(60)
      end
    end

    describe "increment_rate_limiter" do
      it "increments the delivery_request count" do
        expect(rate_limiter).to receive(:add).with("delivery_request")
        subject.increment_rate_limiter
      end
    end

    describe "rate_limit_exceeded?" do
      it "checks the delivery_request limit" do
        default_threshold = 21600
        default_interval = 60

        expect(rate_limiter).to receive(:exceeded?).with(
          "delivery_request",
          threshold: default_threshold,
          interval: default_interval
        ).and_return(true)

        expect(subject.rate_limit_exceeded?).to eq(true)
      end
    end

    describe "check_rate_limit!" do
      context "rate limit not exceeded" do
        before do
          allow(rate_limiter).to receive(:exceeded?).and_return(false)
        end

        it "doesn't raise" do
          expect {
            subject.check_rate_limit!
          }.not_to raise_error
        end
      end

      context "rate limit exceeded" do
        before do
          allow(rate_limiter).to receive(:exceeded?).and_return(true)
        end

        it "raises a RatelimitExceededError" do
          expect {
            subject.check_rate_limit!
          }.to raise_error(RatelimitExceededError)
        end
      end
    end
  end
end

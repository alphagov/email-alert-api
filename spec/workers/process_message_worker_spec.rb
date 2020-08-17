RSpec.describe ProcessMessageWorker do
  let(:message) do
    create(
      :message,
      criteria_rules: [
        { type: "tag", key: "topics", value: "oil-and-gas/licensing" },
      ],
    )
  end

  let(:subscriber_list) do
    create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } })
  end

  describe "#perform" do
    it "matches the message to subscriber lists" do
      expect { described_class.new.perform(message.id) }
        .to change { MatchedMessage.exists?(message: message, subscriber_list: subscriber_list) }
        .to(true)
    end

    it "delegates to ImmediateEmailGenerationService" do
      expect(ImmediateEmailGenerationService).to receive(:call)
                                             .with(message)

      described_class.new.perform(message.id)
    end

    it "can send a courtesy copy email" do
      create(:subscriber, address: Email::COURTESY_EMAIL)
      email = create(:email)

      expect(MessageEmailBuilder)
        .to receive(:call)
        .with([hash_including(address: Email::COURTESY_EMAIL)])
        .and_return([email.id])

      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(email.id, queue: :delivery_immediate)

      described_class.new.perform(message.id)
    end

    it "marks a message as processed" do
      freeze_time do
        expect { described_class.new.perform(message.id) }
          .to change { message.reload.processed_at }
          .to(Time.zone.now)
      end
    end

    it "does nothing if the message is already processed" do
      processed_message = create(:message, processed_at: Time.zone.now)

      expect(ImmediateEmailGenerationService).not_to receive(:call)
      expect(DeliveryRequestWorker).not_to receive(:perform_async_in_queue)

      described_class.new.perform(processed_message.id)
    end
  end

  describe ".perform_async" do
    # We're expecting redis-namespace to raise a warning unfortunately
    before { allow_any_instance_of(Redis::Namespace).to receive(:warn) }

    around do |example|
      SidekiqUniqueJobs.use_config(enabled: true, logger: Logger.new("/dev/null")) do
        example.run
      end
    end

    it "enforces job uniqueness with the correct sidekiq-unique-jobs option" do
      expect(described_class).to receive(:uniqueness_with).with([message.id])
      described_class.perform_async(message.id)
    end
  end
end

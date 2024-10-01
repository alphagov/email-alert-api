RSpec.describe ProcessMessageJob do
  let(:message) do
    create(
      :message,
      criteria_rules: [
        { type: "tag", key: "tribunal_decision_categories", value: "transfer-of-undertakings" },
      ],
    )
  end

  let(:subscriber_list) do
    create(:subscriber_list, tags: { tribunal_decision_categories: { any: %w[transfer-of-undertakings] } })
  end

  describe "#perform" do
    it "matches the message to subscriber lists" do
      expect { described_class.new.perform(message.id) }
        .to change { MatchedMessage.exists?(message:, subscriber_list:) }
        .to(true)
    end

    it "delegates to ImmediateEmailGenerationService" do
      expect(ImmediateEmailGenerationService).to receive(:call)
                                             .with(message)

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
      expect(SendEmailWorker).not_to receive(:perform_async_in_queue)

      described_class.new.perform(processed_message.id)
    end
  end
end

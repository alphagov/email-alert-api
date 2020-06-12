RSpec.describe ProcessContentChangeWorker do
  let(:content_change) do
    create(:content_change, tags: { topics: ["oil-and-gas/licensing"] })
  end

  let(:subscriber_list) do
    create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } })
  end

  describe "#perform" do
    it "matches the content change to subscriber lists" do
      attributes = {
        content_change: content_change,
        subscriber_list: subscriber_list,
      }

      expect { described_class.new.perform(content_change.id) }
        .to change { MatchedContentChange.exists?(attributes) }
        .to(true)
    end

    it "delegates to ImmediateEmailGenerationService" do
      expect(ImmediateEmailGenerationService).to receive(:call)
                                             .with(content_change)
      described_class.new.perform(content_change.id)
    end

    it "can send a courtesy copy email" do
      create(:subscriber, address: Email::COURTESY_EMAIL)
      email = create(:email)

      expect(ContentChangeEmailBuilder)
        .to receive(:call)
        .with([hash_including(address: Email::COURTESY_EMAIL)])
        .and_return([email.id])

      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(email.id, queue: :delivery_immediate)

      described_class.new.perform(content_change.id)
    end

    it "marks a content change as processed" do
      expect { described_class.new.perform(content_change.id) }
        .to change { content_change.reload.processed? }
        .to(true)
    end

    it "does nothing if the content change is already processed" do
      processed_content = create(:content_change, processed_at: Time.zone.now)

      expect(ImmediateEmailGenerationService).not_to receive(:call)
      expect(DeliveryRequestWorker).not_to receive(:perform_async_in_queue)

      described_class.new.perform(processed_content.id)
    end
  end
end

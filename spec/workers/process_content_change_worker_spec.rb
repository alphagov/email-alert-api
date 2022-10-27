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
        content_change:,
        subscriber_list:,
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

    it "marks a content change as processed" do
      freeze_time do
        expect { described_class.new.perform(content_change.id) }
          .to change { content_change.reload.processed_at }
          .to(Time.zone.now)
      end
    end

    it "does nothing if the content change is already processed" do
      processed_content = create(:content_change, processed_at: Time.zone.now)

      expect(ImmediateEmailGenerationService).not_to receive(:call)
      expect(SendEmailWorker).not_to receive(:perform_async_in_queue)

      described_class.new.perform(processed_content.id)
    end
  end
end

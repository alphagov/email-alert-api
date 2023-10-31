RSpec.describe DigestRunSubscriber do
  describe ".populate" do
    let(:digest_run) { create(:digest_run) }

    it "inserts digest run subscribers" do
      subscribers = create_list(:subscriber, 2)
      expect { described_class.populate(digest_run, subscribers.map(&:id)) }
        .to change { described_class.count }.by(2)
    end

    it "sets the appropriate attributes" do
      freeze_time do
        subscriber = create(:subscriber)
        described_class.populate(digest_run, [subscriber.id])
        expect(described_class.last).to have_attributes(
          digest_run_id: digest_run.id,
          subscriber_id: subscriber.id,
          created_at: Time.zone.now,
          updated_at: Time.zone.now,
        )
      end
    end

    it "returns an array of ids" do
      subscriber = create(:subscriber)
      ids = described_class.populate(digest_run, [subscriber.id])
      expect(ids).to eq([described_class.last.id])
    end
  end
end

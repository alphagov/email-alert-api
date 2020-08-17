RSpec.describe DigestInitiatorService do
  describe ".call" do
    let(:subscribers) { create_list(:subscriber, 2) }

    before do
      allow(DigestRunSubscriberQuery).to receive(:call).and_return(subscribers)
      allow(DigestEmailGenerationWorker).to receive(:perform_async)
    end

    context "when a digest run doesn't exist" do
      it "creates a digest run for the current data with the specified range" do
        expect { described_class.call(range: Frequency::DAILY) }
          .to change { DigestRun.daily.where(date: Date.current).count }
          .by(1)

        expect { described_class.call(range: Frequency::WEEKLY) }
          .to change { DigestRun.weekly.where(date: Date.current).count }
          .by(1)
      end

      it "marks the digest run as processed" do
        freeze_time do
          described_class.call(range: Frequency::DAILY)
          digest_run = DigestRun.last
          expect(digest_run.processed_at).to eq(Time.zone.now)
        end
      end

      it "creates a DigestRunSubscriber for each subscription" do
        expect { described_class.call(range: Frequency::DAILY) }
          .to change { DigestRunSubscriber.exists?(subscriber: subscribers) }
          .to(true)
      end

      it "enqueues DigestEmailGenerationWorker for each DigestRunSubscriber" do
        described_class.call(range: Frequency::DAILY)
        ids = DigestRunSubscriber.last(2).pluck(:id)
        expect(DigestEmailGenerationWorker).to have_received(:perform_async).with(ids[0])
        expect(DigestEmailGenerationWorker).to have_received(:perform_async).with(ids[1])
      end
    end

    context "when a digest run already exists" do
      it "exits without creating any DigestRunSubscribers" do
        create(:digest_run, range: Frequency::DAILY, date: Date.current)
        expect { described_class.call(range: Frequency::DAILY) }
          .not_to(change { DigestRunSubscriber.count })
      end
    end
  end
end

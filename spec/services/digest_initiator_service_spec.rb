RSpec.describe DigestInitiatorService do
  describe ".call" do
    let(:subscribers) { create_list(:subscriber, 2) }

    before do
      allow(DigestRunSubscriberQuery).to receive(:call).and_return(subscribers)
      allow(DigestEmailGenerationWorker).to receive(:perform_async)
    end

    context "when a digest run isn't processed" do
      it "can create a digest run for the current data with the specified range" do
        expect { described_class.call(date: Date.current, range: Frequency::DAILY) }
          .to change { DigestRun.daily.where(date: Date.current).count }
          .by(1)

        saturday = Date.new(2020, 9, 5)

        expect { described_class.call(date: saturday, range: Frequency::WEEKLY) }
          .to change { DigestRun.weekly.where(date: saturday).count }
          .by(1)
      end

      it "marks the digest run as processed" do
        freeze_time do
          described_class.call(date: Date.current, range: Frequency::DAILY)
          digest_run = DigestRun.last
          expect(digest_run.processed_at).to eq(Time.zone.now)
        end
      end

      it "creates a DigestRunSubscriber for each subscription" do
        expect { described_class.call(date: Date.current, range: Frequency::DAILY) }
          .to change { DigestRunSubscriber.exists?(subscriber: subscribers) }
          .to(true)
      end

      it "enqueues DigestEmailGenerationWorker for each DigestRunSubscriber" do
        described_class.call(date: Date.current, range: Frequency::DAILY)
        ids = DigestRunSubscriber.last(2).pluck(:id)
        expect(DigestEmailGenerationWorker).to have_received(:perform_async).with(ids[0])
        expect(DigestEmailGenerationWorker).to have_received(:perform_async).with(ids[1])
      end

      it "can resume a partially processed digest run" do
        digest_run = create(:digest_run,
                            range: Frequency::DAILY,
                            date: Date.current)
        create(:digest_run_subscriber,
               digest_run: digest_run,
               subscriber: subscribers.first)

        freeze_time do
          expect { described_class.call(date: Date.current, range: Frequency::DAILY) }
            .to change { DigestRunSubscriber.exists?(subscriber: subscribers.last) }
            .to(true)
            .and change { digest_run.reload.processed_at }
            .from(nil)
            .to(Time.zone.now)
        end
      end
    end

    context "when the digest run is already processed" do
      it "exits without creating any DigestRunSubscribers" do
        create(:digest_run,
               range: Frequency::DAILY,
               date: Date.current,
               processed_at: Time.zone.now)
        expect { described_class.call(date: Date.current, range: Frequency::DAILY) }
          .not_to(change { DigestRunSubscriber.count })
      end
    end
  end
end

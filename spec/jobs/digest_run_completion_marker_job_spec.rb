RSpec.describe DigestRunCompletionMarkerJob, type: :worker do
  describe "#perform" do
    context "when a digest run is processed and has processed subscribers" do
      let(:digest_run) { create(:digest_run, processed_at: Time.zone.now) }
      let(:completed_time) { Date.yesterday.midday }

      before do
        create(:digest_run_subscriber, digest_run:, processed_at: completed_time)
        create(:digest_run_subscriber, digest_run:, processed_at: completed_time)
      end

      it "marks the digest run as complete at the most recent subscriber completion time" do
        expect { subject.perform }
          .to change { digest_run.reload.completed_at }
          .to(completed_time)
      end
    end

    context "when a digest run is processed and has unprocessed subscribers" do
      let(:digest_run) { create(:digest_run, processed_at: Time.zone.now) }

      before do
        create(:digest_run_subscriber, digest_run:)
        create(:digest_run_subscriber, digest_run:, processed_at: Time.zone.now)
      end

      it "doesn't mark the digest run as complete" do
        expect { subject.perform }.not_to(change { digest_run.reload.completed_at })
      end
    end

    context "when a digest run is unprocessed and doesn't have subscribers" do
      let(:digest_run) { create(:digest_run, processed_at: nil) }

      it "doesn't mark the digest run as complete" do
        expect { subject.perform }.not_to(change { digest_run.reload.completed_at })
      end
    end
  end
end

RSpec.describe DigestRunCompletionMarkerWorker, type: :worker do
  describe "#perform" do
    let(:digest_run) { create(:digest_run) }

    context "when a digest_run has incomplete subscribers" do
      before do
        create(:digest_run_subscriber, digest_run: digest_run)
        create(:digest_run_subscriber, digest_run: digest_run, completed_at: Time.zone.now)
      end

      it "doesn't mark the digest run complete" do
        expect { subject.perform }
          .not_to(change { digest_run.reload.completed_at })
      end
    end

    context "when a digest_run has complete subscribers" do
      let(:completed_time) { Date.yesterday.midday }

      before do
        create(:digest_run_subscriber, digest_run: digest_run, completed_at: completed_time)
        create(:digest_run_subscriber, digest_run: digest_run, completed_at: completed_time)
      end

      it "marks the digest run as complete at the most recent subscriber completion time" do
        expect { subject.perform }
          .to change { digest_run.reload.completed_at }
          .to(completed_time)
      end
    end
  end
end

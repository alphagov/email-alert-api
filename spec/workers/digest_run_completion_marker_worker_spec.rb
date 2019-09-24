require "rails_helper"

RSpec.describe DigestRunCompletionMarkerWorker, type: :worker do
  describe "#perform" do
    let(:digest_run) { create(:digest_run) }

    context "when a digest_run has incomplete subscribers" do
      before do
        create(:digest_run_subscriber, digest_run: digest_run)
        create(:digest_run_subscriber, digest_run: digest_run, completed_at: Time.now)
      end

      it "doesn't mark the digest run complete" do
        expect { subject.perform }
          .not_to(change { digest_run.reload.completed? })
      end
    end

    context "when a digest_run has complete subscribers" do
      before do
        create(:digest_run_subscriber, digest_run: digest_run, completed_at: Time.mktime(2018, 1, 1, 10))
        create(:digest_run_subscriber, digest_run: digest_run, completed_at: Time.mktime(2018, 1, 1, 9))
      end

      it "marks the digest run as complete at the most recent subscriber completion time" do
        expect { subject.perform }
          .to(change { digest_run.reload.completed? }
            .from(false)
            .to(true))

        expect(digest_run.completed_at).to eq Time.mktime(2018, 1, 1, 10)
      end
    end
  end
end

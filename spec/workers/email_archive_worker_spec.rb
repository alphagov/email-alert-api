RSpec.describe EmailArchiveWorker do
  describe "#perform" do
    def perform
      described_class.new.perform
    end

    context "when there are no emails to archive" do
      before do
        create(:unarchivable_email)
        create(:archived_email)
      end
      it "doesn't change the number of EmailArchive records" do
        expect { perform }.not_to(change { EmailArchive.count })
      end
    end

    context "when there are emails to archive" do
      let!(:emails) { 3.times.map { create(:archivable_email) } }

      it "adds EmailArchive records" do
        expect { perform }.to change { EmailArchive.count }.by(3)
      end

      it "adds an archived_at field to emails" do
        expect { perform }
          .to change { emails.map { |e| e.reload.archived_at }.uniq }
          .from([nil])
          .to(match_array([an_instance_of(ActiveSupport::TimeWithZone)]))
      end

      it "sets approriate EmailArchive fields" do
        perform
        email = emails.last.reload
        email_archive = EmailArchive.find(email.id)

        expect(email_archive.created_at).to eq email.created_at
        expect(email_archive.subject).to eq email.subject
        expect(email_archive.finished_sending_at).to eq email.finished_sending_at
        expect(email_archive.archived_at).to eq email.archived_at
      end
    end

    context "when an email is not associated with content changes" do
      let!(:email) { create(:archivable_email) }

      it "has a nil content change field" do
        perform
        expect(EmailArchive.find(email.id).content_change).to be nil
      end
    end

    context "when an email is associated with content changes" do
      let!(:subscription_content) do
        create(:subscription_content, :with_archivable_email)
      end
      let(:email) { subscription_content.email }
      let(:subscription) { subscription_content.subscription }

      it "has content change details" do
        perform
        email_archive = EmailArchive.find(email.id)
        expect(email_archive.subscriber_id).to eq subscription.subscriber_id
        expect(email_archive.content_change).to match(
          hash_including(
            "content_change_ids" => [subscription_content.content_change_id],
            "digest_run_id" => nil,
            "subscription_ids" => [subscription_content.subscription_id],
          )
        )
      end
    end

    context "when an email is associated with a digest" do
      let(:subscriber) { create(:subscriber) }
      let(:digest_run_subscriber) do
        create(:digest_run_subscriber, subscriber: subscriber)
      end

      let!(:subscription_content) do
        create(
          :subscription_content,
          :with_archivable_email,
          subscription: create(:subscription, subscriber: subscriber),
          digest_run_subscriber: digest_run_subscriber,
        )
      end
      let(:email) { subscription_content.email }

      it "has digest id" do
        perform
        email_archive = EmailArchive.find(email.id)
        expect(email_archive.content_change).to match(
          hash_including(
            "digest_run_id" => digest_run_subscriber.digest_run_id
          )
        )
      end
    end
  end
end

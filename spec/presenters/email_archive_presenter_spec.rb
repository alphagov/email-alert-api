require "rails_helper"

RSpec.describe EmailArchivePresenter do
  let(:time_bst) { Time.parse("2018-07-01 10:00 +0100") }
  let(:time_for_s3) { "2018-07-01 09:00:00.000" }

  let(:record) do
    {
      "content_change_ids" => [SecureRandom.uuid],
      "digest_run_ids" => [1],
      "created_at" => time_bst,
      "finished_sending_at" => time_bst,
      "id" => SecureRandom.uuid,
      "marked_as_spam" => false,
      "sent" => true,
      "subject" => "Test email",
      "subscriber_id" => 1,
      "subscription_ids" => [SecureRandom.uuid],
    }
  end

  let(:archived_at) { time_bst }

  describe ".for_s3" do
    it "presents the data" do
      expect(described_class.for_s3(record, archived_at)).to eq(
        archived_at_utc: time_for_s3,
        content_change: {
          content_change_ids: record["content_change_ids"],
          digest_run_id: record["digest_run_ids"].first,
          subscription_ids: record["subscription_ids"],
        },
        created_at_utc: time_for_s3,
        finished_sending_at_utc: time_for_s3,
        id: record["id"],
        marked_as_spam: false,
        sent: record["sent"],
        subject: record["subject"],
        subscriber_id: record["subscriber_id"],
      )
    end


    context "when there are required keys missing" do
      it "raises a KeyError" do
        expect { described_class.for_s3(record.except("id"), archived_at) }
          .to raise_error(KeyError)
      end
    end

    context "when there are multiple digest_run_ids" do
      before do
        record["digest_run_ids"] = [1, 2, 3]
        allow(GovukError).to receive(:notify)
      end

      it "only returns one of them" do
        expect(described_class.for_s3(record, archived_at)).to match(
          hash_including(content_change: hash_including(digest_run_id: 1)),
        )
      end

      it "notifies the error service" do
        expect(GovukError).to receive(:notify)
        described_class.for_s3(record, archived_at)
      end
    end
  end
end

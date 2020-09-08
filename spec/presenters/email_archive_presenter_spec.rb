RSpec.describe EmailArchivePresenter do
  let(:time_bst) { Time.zone.parse("2018-07-01 10:00 +0100") }
  let(:time_for_s3) { "2018-07-01 09:00:00.000" }

  let(:record) do
    {
      "content_change_ids" => [],
      "message_ids" => [],
      "digest_run_ids" => [1],
      "created_at" => time_bst,
      "id" => SecureRandom.uuid,
      "subject" => "Test email",
      "subscriber_id" => 1,
      "subscription_ids" => [SecureRandom.uuid],
    }
  end

  let(:archived_at) { time_bst }

  describe ".for_s3" do
    context "for a content change" do
      let(:content_change) do
        record.merge("content_change_ids" => [SecureRandom.uuid])
      end

      it "presents the data" do
        expect(described_class.for_s3(content_change, archived_at)).to eq(
          archived_at_utc: time_for_s3,
          message: nil,
          content_change: {
            content_change_ids: content_change["content_change_ids"],
            digest_run_id: content_change["digest_run_ids"].first,
            subscription_ids: content_change["subscription_ids"],
          },
          created_at_utc: time_for_s3,
          id: record["id"],
          subject: record["subject"],
          subscriber_id: record["subscriber_id"],
        )
      end
    end

    context "for a message" do
      let(:message) do
        record.merge("message_ids" => [SecureRandom.uuid])
      end

      it "presents the data" do
        expect(described_class.for_s3(message, archived_at)).to eq(
          archived_at_utc: time_for_s3,
          content_change: nil,
          message: {
            message_ids: message["message_ids"],
            digest_run_id: message["digest_run_ids"].first,
            subscription_ids: message["subscription_ids"],
          },
          created_at_utc: time_for_s3,
          id: record["id"],
          subject: record["subject"],
          subscriber_id: record["subscriber_id"],
        )
      end
    end

    context "when there are required keys missing" do
      it "raises a KeyError" do
        expect { described_class.for_s3(record.except("id"), archived_at) }
          .to raise_error(KeyError)
      end
    end
  end
end

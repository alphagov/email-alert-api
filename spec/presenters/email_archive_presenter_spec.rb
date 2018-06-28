require "rails_helper"

RSpec.describe EmailArchivePresenter do
  describe ".call" do
    let(:record) do
      {
        "content_change_ids" => [SecureRandom.uuid],
        "digest_run_ids" => [1],
        "created_at" => Time.now,
        "finished_sending_at" => Time.now,
        "id" => SecureRandom.uuid,
        "sent" => true,
        "subject" => "Test email",
        "subscriber_id" => 1,
        "subscription_ids" => [SecureRandom.uuid]
      }
    end

    let(:archived_at) { Time.now }

    it "presents the data" do
      expect(described_class.call(record, archived_at)).to eq(
        archived_at: archived_at,
        content_change: {
          content_change_ids: record["content_change_ids"],
          digest_run_id: record["digest_run_ids"].first,
          subscription_ids: record["subscription_ids"]
        },
        created_at: record["created_at"],
        finished_sending_at: record["finished_sending_at"],
        id: record["id"],
        sent: record["sent"],
        subject: record["subject"],
        subscriber_id: record["subscriber_id"],
      )
    end


    context "when there are required keys missing" do
      it "raises a KeyError" do
        expect { described_class.call(record.except("id"), archived_at) }
          .to raise_error(KeyError)
      end
    end

    context "when there are multiple digest_run_ids" do
      before do
        record["digest_run_ids"] = [1, 2, 3]
        allow(GovukError).to receive(:notify)
      end

      it "only returns one of them" do
        expect(described_class.call(record, archived_at)).to match(
          hash_including(content_change: hash_including(digest_run_id: 1))
        )
      end

      it "notifies the error service" do
        expect(GovukError).to receive(:notify)
        described_class.call(record, archived_at)
      end
    end
  end
end

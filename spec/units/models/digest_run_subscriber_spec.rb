require "rails_helper"

RSpec.describe DigestRunSubscriber do
  subject { build(:digest_run_subscriber) }

  describe "mark_complete!" do
    it "sets completed_at to Time.now" do
      Timecop.freeze do
        subject.mark_complete!
        expect(subject.completed_at).to eq(Time.now)
      end
    end
  end

  describe "incomplete_for_run" do
    it "returns records with the supplied digest_run_id that have completed_at nil" do
      create(:digest_run, id: 1)
      digest_run_subscriber = create(
        :digest_run_subscriber,
        digest_run_id: 1,
        completed_at: nil
      )

      expect(described_class.incomplete_for_run(1).first).to eq(digest_run_subscriber)
    end

    it "doesn't return completed_records" do
      create(:digest_run, id: 1)
      create(
        :digest_run_subscriber,
        digest_run_id: 1,
        completed_at: Time.now
      )

      expect(described_class.incomplete_for_run(1).count).to eq(0)
    end

    it "doesn't return records from other runs" do
      create(:digest_run, id: 2)
      create(
        :digest_run_subscriber,
        digest_run_id: 2,
        completed_at: nil
      )

      expect(described_class.incomplete_for_run(1).count).to eq(0)
    end
  end
end

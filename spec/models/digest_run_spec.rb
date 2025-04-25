RSpec.describe DigestRun do
  around do |example|
    saturday = Time.zone.parse("2020-09-05 09:30")
    travel_to(saturday) { example.run }
  end

  context "with valid parameters" do
    it "can be created" do
      expect {
        described_class.create(
          attributes_for(:digest_run),
        )
      }.to change { DigestRun.count }.from(0).to(1)
    end

    context "daily" do
      it "sets starts_at to 8am on date - 1.day" do
        instance = described_class.create!(date: Date.current, range: "daily")
        expect(instance.starts_at).to eq(Time.zone.parse("08:00", Date.current - 1.day))
      end

      it "sets ends_at to 8am on date" do
        instance = described_class.create!(date: Date.current, range: "daily")
        expect(instance.ends_at).to eq(Time.zone.parse("08:00", Date.current))
      end
    end

    context "weekly" do
      it "sets starts_at to 8am on date - 1.week" do
        instance = described_class.create!(date: Date.current, range: "weekly")
        expect(instance.starts_at).to eq(Time.zone.parse("08:00", Date.current - 1.week))
      end

      it "sets ends_at to 8am on date" do
        instance = described_class.create!(date: Date.current, range: "weekly")
        expect(instance.ends_at).to eq(Time.zone.parse("08:00", Date.current))
      end
    end

    describe "validations" do
      it "fails if the calculated ends_at is in the future" do
        instance = described_class.new(date: Date.current + 1.day, range: "daily")
        instance.validate
        expected_time = "#{DigestRun::DIGEST_RANGE_HOUR}:00"
        expect(instance.errors[:date]).to eq(["must be in the past, or today if after #{expected_time}"])
      end

      it "fails if a weekly digest does not end on a Saturday" do
        instance = described_class.new(date: Date.current - 1.day, range: "weekly")
        instance.validate
        expect(instance.errors[:date]).to eq(["must be a Saturday for weekly digests"])
      end
    end
  end

  describe "#mark_as_completed" do
    let(:digest_run) { create(:digest_run) }

    context "when there are digest_run_subscribers" do
      let(:digest_run_subscriber) do
        create(:digest_run_subscriber, digest_run_id: digest_run.id, processed_at: Time.zone.now)
      end

      it "marks the digest run as completed based on the digest run subscriber proceesed time" do
        expect { digest_run.mark_as_completed }
          .to change { digest_run.completed_at }
          .to(digest_run_subscriber.reload.processed_at)
      end
    end

    context "when there aren't digest_run_subscribers" do
      it "marks the digest run as completed based on the current time" do
        expect { digest_run.mark_as_completed }
          .to change { digest_run.completed_at }
          .to(Time.zone.now)
      end
    end
  end
end

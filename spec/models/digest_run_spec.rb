RSpec.describe DigestRun do
  context "with valid parameters" do
    it "can be created" do
      expect {
        described_class.create(
          attributes_for(:digest_run),
        )
      }.to change { DigestRun.count }.from(0).to(1)
    end

    context "with no environment vars set" do
      context "daily" do
        it "sets starts_at to 8am on date - 1.day" do
          date = 2.days.ago
          instance = described_class.create!(date: date, range: "daily")

          expect(instance.starts_at).to eq(
            Time.zone.parse("08:00", date - 1.day),
          )
        end

        it "sets ends_at to 8am on date" do
          date = 1.day.ago
          instance = described_class.create!(date: date, range: "daily")

          expect(instance.ends_at).to eq(
            Time.zone.parse("08:00", date),
          )
        end
      end

      context "weekly" do
        it "sets starts_at to 8am on date - 1.week" do
          saturday = Date.new(2020, 9, 5)
          instance = described_class.create!(date: saturday, range: "weekly")

          expect(instance.starts_at).to eq(
            Time.zone.parse("08:00", (saturday - 1.week)),
          )
        end

        it "sets ends_at to 8am on date" do
          saturday = Date.new(2020, 9, 5)
          instance = described_class.create!(date: saturday, range: "weekly")

          expect(instance.ends_at).to eq(
            Time.zone.parse("08:00", saturday),
          )
        end
      end
    end

    context "configured with an env var" do
      around do |example|
        ClimateControl.modify(DIGEST_RANGE_HOUR: "10") do
          travel_to(Time.zone.parse("10:30")) { example.run }
        end
      end

      context "daily" do
        it "sets starts_at to the configured hour on date - 1.day" do
          date = 1.week.ago
          instance = described_class.create!(date: date, range: "daily")

          expect(instance.starts_at).to eq(
            Time.zone.parse("10:00", (date - 1.day)),
          )
        end

        it "sets ends_at to the configured hour on date" do
          date = 1.day.ago
          instance = described_class.create!(date: date, range: "daily")

          expect(instance.ends_at).to eq(
            Time.zone.parse("10:00", date),
          )
        end
      end

      context "weekly" do
        it "sets starts_at to the configured hour on date - 1.week" do
          saturday = Date.new(2020, 9, 5)
          instance = described_class.create!(date: saturday, range: "weekly")

          expect(instance.starts_at).to eq(
            Time.zone.parse("10:00", (saturday - 1.week)),
          )
        end

        it "sets ends_at to the configured hour on date" do
          saturday = Date.new(2020, 9, 5)
          instance = described_class.create!(date: saturday, range: "weekly")

          expect(instance.ends_at).to eq(
            Time.zone.parse("10:00", saturday),
          )
        end
      end
    end

    describe "validations" do
      it "fails if the calculated ends_at is in the future" do
        travel_to(Time.zone.parse("07:00")) do
          instance = described_class.new(date: Date.current, range: "daily")
          instance.validate
          expect(instance.errors[:ends_at]).to eq(["must be in the past"])
        end
      end

      it "fails if a weekly digest does not end on a Saturday" do
        instance = described_class.new(date: Date.new(2020, 9, 10), range: "weekly")
        instance.validate
        expect(instance.errors[:ends_at]).to eq(["must be a Saturday for weekly digests"])
      end
    end
  end

  context "when we are in British Summer Time" do
    around do |example|
      travel_to("2018-03-31 07:30 UTC") { example.run }
    end

    it "creates a digest run without errors" do
      described_class.create!(date: Date.current, range: :daily)
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
        freeze_time do
          expect { digest_run.mark_as_completed }
            .to change { digest_run.completed_at }
            .to(Time.zone.now)
        end
      end
    end
  end
end

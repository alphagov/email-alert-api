require "rails_helper"

RSpec.describe DigestRun do
  context "with valid parameters" do
    it "can be created" do
      expect {
        described_class.create(
          attributes_for(:digest_run)
        )
      }.to change { DigestRun.count }.from(0).to(1)
    end

    context "with no environment vars set" do
      context "daily" do
        it "sets starts_at to 8am on date - 1.day" do
          date = 2.days.ago
          instance = described_class.create(date: date, range: "daily")

          expect(instance.starts_at).to eq(
            Time.parse("08:00", (date - 1.day).to_time)
          )
        end

        it "sets ends_at to 8am on date" do
          date = 1.day.ago
          instance = described_class.create(date: date, range: "daily")

          expect(instance.ends_at).to eq(
            Time.parse("08:00", date.to_time)
          )
        end
      end

      context "weekly" do
        it "sets starts_at to 8am on date - 1.week" do
          date = 1.day.ago
          instance = described_class.create(date: date, range: "weekly")

          expect(instance.starts_at).to eq(
            Time.parse("08:00", (date - 1.week).to_time)
          )
        end

        it "sets ends_at to 8am on date" do
          date = Date.current
          instance = described_class.create(date: date, range: "weekly")

          expect(instance.ends_at).to eq(
            Time.parse("08:00", date.to_time)
          )
        end
      end
    end

    context "configured with an env var" do
      before do
        ENV["DIGEST_RANGE_HOUR"] = "10"
        Timecop.freeze("10:30", Time.now)
      end

      after do
        ENV["DIGEST_RANGE_HOUR"] = nil
        Timecop.return
      end

      context "daily" do
        it "sets starts_at to the configured hour on date - 1.day" do
          date = 1.week.ago
          instance = described_class.create(date: date, range: "daily")

          expect(instance.starts_at).to eq(
            Time.parse("10:00", (date - 1.day).to_time)
          )
        end

        it "sets ends_at to the configured hour on date" do
          date = 1.day.ago
          instance = described_class.create(date: date, range: "daily")

          expect(instance.ends_at).to eq(
            Time.parse("10:00", date.to_time)
          )
        end
      end

      context "weekly" do
        it "sets starts_at to the configured hour on date - 1.week" do
          date = Date.current
          instance = described_class.create(date: date, range: "weekly")

          expect(instance.starts_at).to eq(
            Time.parse("10:00", (date - 1.week).to_time)
          )
        end

        it "sets ends_at to the configured hour on date" do
          date = 4.days.ago
          instance = described_class.create(date: date, range: "weekly")

          expect(instance.ends_at).to eq(
            Time.parse("10:00", date.to_time)
          )
        end
      end
    end

    describe "validations" do
      it "fails if the calculated ends_at is in the future" do
        Timecop.freeze(Time.parse("07:00", Time.now)) do
          instance = described_class.create(date: Date.current, range: "daily")
          expect(instance.errors[:ends_at]).to eq(["must be in the past"])
        end
      end
    end
  end

  describe "#mark_complete!" do
    it "sets completed_at to Time.now" do
      Timecop.freeze do
        digest_run = create(:digest_run)
        digest_run.mark_complete!
        digest_run.reload
        expect(digest_run.completed_at.change(nsec: 0)).to eq(Time.now.change(nsec: 0))
      end
    end
  end
end

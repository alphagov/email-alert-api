require "rails_helper"

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
          instance = described_class.create(date: date, range: "daily")

          expect(instance.starts_at).to eq(
            Time.zone.parse("08:00", (date - 1.day).to_time),
          )
        end

        it "sets ends_at to 8am on date" do
          date = 1.day.ago
          instance = described_class.create(date: date, range: "daily")

          expect(instance.ends_at).to eq(
            Time.zone.parse("08:00", date.to_time),
          )
        end
      end

      context "weekly" do
        it "sets starts_at to 8am on date - 1.week" do
          date = 1.day.ago
          instance = described_class.create(date: date, range: "weekly")

          expect(instance.starts_at).to eq(
            Time.zone.parse("08:00", (date - 1.week).to_time),
          )
        end

        it "sets ends_at to 8am on date" do
          date = Date.current
          instance = described_class.create(date: date, range: "weekly")

          expect(instance.ends_at).to eq(
            Time.zone.parse("08:00", date.to_time),
          )
        end
      end
    end

    context "configured with an env var" do
      before do
        ENV["DIGEST_RANGE_HOUR"] = "10"
        Timecop.freeze("10:30", Time.zone.now)
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
            Time.zone.parse("10:00", (date - 1.day).to_time),
          )
        end

        it "sets ends_at to the configured hour on date" do
          date = 1.day.ago
          instance = described_class.create(date: date, range: "daily")

          expect(instance.ends_at).to eq(
            Time.zone.parse("10:00", date.to_time),
          )
        end
      end

      context "weekly" do
        it "sets starts_at to the configured hour on date - 1.week" do
          date = Date.current
          instance = described_class.create(date: date, range: "weekly")

          expect(instance.starts_at).to eq(
            Time.zone.parse("10:00", (date - 1.week).to_time),
          )
        end

        it "sets ends_at to the configured hour on date" do
          date = 4.days.ago
          instance = described_class.create(date: date, range: "weekly")

          expect(instance.ends_at).to eq(
            Time.zone.parse("10:00", date.to_time),
          )
        end
      end
    end

    describe "validations" do
      it "fails if the calculated ends_at is in the future" do
        Timecop.freeze(Time.zone.parse("07:00", Time.now)) do
          instance = described_class.create(date: Date.current, range: "daily")
          expect(instance.errors[:ends_at]).to eq(["must be in the past"])
        end
      end
    end
  end

  context "when we are in British Summer Time" do
    around do |example|
      # A UTC value of a typical time to start the digest
      Timecop.freeze("2018-03-31T07:30:00+00:00") { example.run }
    end

    it "creates a digest run without errors" do
      described_class.create!(date: Date.current, range: :daily)
    end
  end

  describe "#mark_complete!" do
    context "with complete subscribers" do
      it "sets completed_at to the most recent subscriber completed_at" do
        Timecop.freeze do
          digest_run = create(:digest_run)
          create(:digest_run_subscriber, digest_run: digest_run, completed_at: Time.mktime(2018, 1, 1, 10))
          create(:digest_run_subscriber, digest_run: digest_run, completed_at: Time.mktime(2018, 1, 1, 9))
          digest_run.mark_complete!
          digest_run.reload
          expect(digest_run.completed_at).to eq Time.mktime(2018, 1, 1, 10)
        end
      end
    end

    context "with no subscribers" do
      it "sets completed_at to the current time" do
        Timecop.freeze do
          digest_run = create(:digest_run)
          digest_run.mark_complete!
          digest_run.reload
          expect(digest_run.completed_at).to be_within(1.second).of(Time.zone.now)
        end
      end
    end
  end

  describe ".check_and_mark_complete!" do
    let(:subject) { create(:digest_run) }

    context "incomplete digest_run_subscribers" do
      before do
        create(:digest_run_subscriber, digest_run_id: subject.id)
      end

      it "marks the digest run complete" do
        subject.check_and_mark_complete!
        expect(subject.completed_at).to be_nil
      end
    end

    context "no incomplete digest_run_subscribers" do
      before do
        create(:digest_run_subscriber, digest_run_id: subject.id, completed_at: Time.zone.now)
      end
    end

    it "marks the digest run complete" do
      subject.check_and_mark_complete!
      expect(subject.completed_at).not_to be_nil
    end
  end
end

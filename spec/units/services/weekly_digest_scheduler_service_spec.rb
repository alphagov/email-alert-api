require "rails_helper"

RSpec.describe WeeklyDigestSchedulerService do
  describe "call" do
    context "when there is no daily DigestRun for the date" do
      it "creates one" do
        Timecop.freeze(Time.parse("08:30")) do
          expect { described_class.call }
            .to change { DigestRun.weekly.count }.from(0).to(1)
        end
      end
    end

    context "when a DigestRun already exists" do
      it "doesn't create another one" do
        Timecop.freeze(Time.parse("08:30")) do
          create(:digest_run, :weekly, date: Date.current)

          described_class.call

          expect(DigestRun.count).to eq(1)
        end
      end
    end

    context "when the service is called multiple times" do
      it "only creates one DigestRun" do
        Timecop.freeze(Time.parse("08:30")) do
          described_class.call
          described_class.call
          described_class.call
          described_class.call

          expect(DigestRun.count).to eq(1)
        end
      end
    end
  end
end

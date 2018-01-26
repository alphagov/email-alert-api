require "rails_helper"

RSpec.describe DigestInitiatorService do
  describe ".call" do
    context "daily" do
      let(:range) { DigestRun::DAILY }

      after do
        ENV["DIGEST_RANGE_HOUR"] = nil
      end

      context "when there is no daily DigestRun for the date" do
        it "creates one" do
          Timecop.freeze(Time.parse("08:30")) do
            expect { described_class.call(range: range) }
              .to change { DigestRun.daily.count }.from(0).to(1)
          end
        end
      end

      context "when a DigestRun already exists" do
        it "doesn't create another one" do
          Timecop.freeze(Time.parse("08:30")) do
            create(:digest_run, :daily, date: Date.current)

            described_class.call(range: range)

            expect(DigestRun.count).to eq(1)
          end
        end
      end

      context "when the service is called multiple times" do
        it "only creates one DigestRun" do
          Timecop.freeze(Time.parse("08:30")) do
            described_class.call(range: range)
            described_class.call(range: range)
            described_class.call(range: range)
            described_class.call(range: range)

            expect(DigestRun.count).to eq(1)
          end
        end
      end

      it "creates a DigestRunSubscriber for each subscriber" do
        subscribers = [ create(:subscriber, id: 1), create(:subscriber, id: 2) ]

        allow(DigestRunSubscriberQuery).to receive(:call).and_return(subscribers)
        described_class.call(range: range)

        expect(DigestRunSubscriber.all.map(&:subscriber_id)).to match([1,2])
      end
    end

    context "weekly" do
      let(:range) { DigestRun::WEEKLY }

      context "when there is no daily DigestRun for the date" do
        it "creates one" do
          Timecop.freeze(Time.parse("08:30")) do
            expect { described_class.call(range: range) }
              .to change { DigestRun.weekly.count }.from(0).to(1)
          end
        end
      end

      context "when a DigestRun already exists" do
        it "doesn't create another one" do
          Timecop.freeze(Time.parse("08:30")) do
            create(:digest_run, :weekly, date: Date.current)

            described_class.call(range: range)

            expect(DigestRun.count).to eq(1)
          end
        end
      end

      context "when the service is called multiple times" do
        it "only creates one DigestRun" do
          Timecop.freeze(Time.parse("08:30")) do
            described_class.call(range: range)
            described_class.call(range: range)
            described_class.call(range: range)
            described_class.call(range: range)

            expect(DigestRun.count).to eq(1)
          end
        end
      end
    end
  end
end

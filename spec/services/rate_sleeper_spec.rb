require 'rails_helper'

RSpec.describe RateSleeper do
  describe ".run" do
    context "with jobs per second = 8" do
      let(:rate_sleeper) {
        RateSleeper.new(jobs_per_second: 8)
      }

      context "with almost 0 execution time" do
        it "sleeps for about 0.125 seconds" do
          #measuring the duration of yield takes a tiny amount
          #of time so it won't be quite 0.125

          allow(rate_sleeper).to receive(:sleep)
          expect(rate_sleeper).to receive(:sleep).with(be_between(0.124, 0.126))

          rate_sleeper.run {}
        end
      end

      context "with 0.05 seconds execution time" do
        it "sleeps for about 0.07 seconds" do
          expect(rate_sleeper).to receive(:sleep).with(be_between(0.06, 0.08))

          rate_sleeper.run {
            Kernel.sleep(0.05)
          }
        end
      end

      context "with execution time slower than the allowed rate" do
        it "doesn't sleep" do
          expect(rate_sleeper).not_to receive(:sleep)

          rate_sleeper.run {
            Kernel.sleep(0.13)
          }
        end
      end
    end

    context "with jobs per second 20" do
      let(:rate_sleeper) {
        RateSleeper.new(jobs_per_second: 20)
      }

      context "with 0.02 seconds execution time" do
        it "sleeps for about 0.03 seconds" do
          expect(rate_sleeper).to receive(:sleep).with(be_between(0.02, 0.03))

          rate_sleeper.run {
            Kernel.sleep(0.02)
          }
        end
      end
    end
  end
end

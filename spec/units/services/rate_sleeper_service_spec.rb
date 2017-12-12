RSpec.describe RateSleeperService do
  describe ".run" do
    context "with jobs per second = 8" do
      subject { described_class.new(jobs_per_second: 8) }

      context "with almost 0 execution time" do
        it "sleeps for about 0.125 seconds" do
          #measuring the duration of yield takes a tiny amount
          #of time so it won't be quite 0.125

          allow(subject).to receive(:sleep)
          expect(subject).to receive(:sleep).with(be_between(0.124, 0.126))

          subject.run {}
        end
      end

      context "with 0.05 seconds execution time" do
        it "sleeps for about 0.07 seconds" do
          expect(subject).to receive(:sleep).with(be_between(0.06, 0.08))

          subject.run {
            Kernel.sleep(0.05)
          }
        end
      end

      context "with execution time slower than the allowed rate" do
        it "doesn't sleep" do
          expect(subject).not_to receive(:sleep)

          subject.run {
            Kernel.sleep(0.13)
          }
        end
      end
    end

    context "with jobs per second 20" do
      subject { described_class.new(jobs_per_second: 20) }

      context "with 0.02 seconds execution time" do
        it "sleeps for about 0.03 seconds" do
          expect(subject).to receive(:sleep).with(be_between(0.02, 0.03))

          subject.run {
            Kernel.sleep(0.02)
          }
        end
      end
    end
  end
end

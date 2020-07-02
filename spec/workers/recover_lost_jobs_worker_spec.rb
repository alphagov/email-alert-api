RSpec.describe RecoverLostJobsWorker do
  before do
    Sidekiq::Worker.clear_all
  end

  describe ".perform" do
    it "does not requeue incomplete content changes that are under 1-hour old" do
      travel_to(59.minutes.ago) do
        2.times { create(:content_change) }
      end

      travel_to(Time.zone.now) do
        expect(ProcessContentChangeWorker).not_to receive(:perform_async)
        subject.perform(ContentChange, ProcessContentChangeWorker)
      end
    end

    it "requeues incomplete content changes that are over 1-hour old" do
      travel_to(1.hour.ago) do
        2.times { create(:content_change) }
      end

      travel_to(Time.zone.now) do
        expect(ProcessContentChangeWorker).to receive(:perform_async).twice
        subject.perform(ContentChange, ProcessContentChangeWorker)
      end
    end

    it "does not requeue incomplete messages that are under 1-hour old" do
      travel_to(59.minutes.ago) do
        2.times { create(:message) }
      end

      travel_to(Time.zone.now) do
        expect(ProcessMessageWorker).not_to receive(:perform_async)
        subject.perform(Message, ProcessMessageWorker)
      end
    end

    it "requeues incomplete messages that are over 1-hour old" do
      travel_to(1.hour.ago) do
        2.times { create(:message) }
      end

      travel_to(Time.zone.now) do
        expect(ProcessMessageWorker).to receive(:perform_async).twice
        subject.perform(Message, ProcessMessageWorker)
      end
    end
  end
end

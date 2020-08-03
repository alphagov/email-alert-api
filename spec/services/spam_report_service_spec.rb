RSpec.describe SpamReportService do
  describe ".call" do
    let(:subscription) { create(:subscription) }
    let(:subscriber) { subscription.subscriber }

    it "delegates to the UnsubscribeService" do
      expect(UnsubscribeService).to receive(:call)
        .with(subscriber, [subscription], :marked_as_spam)

      described_class.call(subscriber)
    end
  end
end

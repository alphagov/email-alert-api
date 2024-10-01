RSpec.describe WeeklyDigestInitiatorJob do
  describe ".perform" do
    it "calls the weekly digest initiator service" do
      expect(DigestInitiatorService).to receive(:call)
        .with(date: Date.current, range: Frequency::WEEKLY)

      subject.perform
    end
  end
end

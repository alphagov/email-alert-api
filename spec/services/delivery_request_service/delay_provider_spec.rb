RSpec.describe DeliveryRequestService::DelayProvider do
  describe ".call" do
    let(:args) do
      {
        address: "email@address.com",
        subject: "subject",
        body: "body",
        reference: "ref-123",
      }
    end

    it "simulates an API delay" do
      expect(Kernel).to receive(:sleep)
      described_class.call(**args)
    end

    it "returns a status of delivered" do
      return_value = described_class.call(**args)
      expect(return_value).to be(:delivered)
    end
  end
end

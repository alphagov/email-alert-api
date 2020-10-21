RSpec.describe SendEmailService::PseudoProvider do
  describe ".call" do
    it "logs to a file" do
      allow(Logger).to receive(:new).and_return(logger = double)

      expect(logger).to receive(:info).with(lambda { |string|
        expect(string).to include("Sending email to email@address.com")
        expect(string).to include("Subject: subject")
        expect(string).to include("Body: body")
        expect(string).to include("Reference: ref-123")
      })

      described_class.call(
        address: "email@address.com",
        subject: "subject",
        body: "body",
        reference: "ref-123",
      )
    end

    it "returns a status of delivered" do
      return_value = described_class.call(
        address: "email@address.com",
        subject: "subject",
        body: "body",
        reference: "ref-123",
      )
      expect(return_value).to be(:delivered)
    end
  end
end

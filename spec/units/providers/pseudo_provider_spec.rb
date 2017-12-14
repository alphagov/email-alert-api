RSpec.describe PseudoProvider do
  it "logs to a file" do
    expect(subject.logger).to receive(:info).with(->(string) {
      expect(string).to include("Sending email to email@address.com")
      expect(string).to include("Subject: subject")
      expect(string).to include("Body: body")
      expect(string).to include("Reference: ref-123")
    })

    subject.call(
      address: "email@address.com",
      subject: "subject",
      body: "body",
      reference: "ref-123",
    )
  end
end

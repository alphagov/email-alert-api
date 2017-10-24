require "rails_helper"
require "notifications/client"

RSpec.describe EmailSender::Notify do
  describe "#call" do
    it "sends an email to the address passed in" do
      client = double
      allow(Notifications::Client)
        .to receive(:new)
        .and_return(client)
      expect(client)
        .to receive(:send_email)
        .with(
          email_address: "email@address.com",
          personalisation: a_hash_including(subject: "subject", body: "body"),
          template_id: anything,
        )

      subject.call(address: "email@address.com", subject: "subject", body: "body")
    end
  end
end

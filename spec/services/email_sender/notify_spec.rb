require "rails_helper"
require "notifications/client"

RSpec.describe EmailSenderService::Notify do
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
        .and_return(double(id: 0))

      expect(subject.call(address: "email@address.com", subject: "subject", body: "body")).to eq(0)
    end
  end
end

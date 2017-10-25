require "rails_helper"

RSpec.describe DeliverToSubscriberWorker do
  let(:email_sender) { double }
  before do
    allow(Services).to receive(:email_sender).and_return(
      email_sender
    )
  end

  describe ".perform" do
    let(:subscriber) { FactoryGirl.create(:subscriber) }
    let(:email) { FactoryGirl.create(:email) }

    context "with an email and a subscriber" do
      it "should send the email to the subscriber" do
        expect(email_sender).to receive(:call)
          .with(
            address: subscriber.address,
            subject: email.subject,
            body: email.body
          )

        Sidekiq::Testing.inline!
        described_class.perform_async(subscriber.id, email.id)
      end
    end
  end
end

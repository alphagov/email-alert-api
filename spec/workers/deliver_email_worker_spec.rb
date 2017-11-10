require "rails_helper"

RSpec.describe DeliverEmailWorker do
  let(:email_sender) { double }
  before do
    allow(email_sender).to receive(:provider_name).and_return(:pseudo)
    allow(Services).to receive(:email_sender).and_return(
      email_sender
    )
  end

  describe ".perform" do
    let(:email) { create(:email) }

    context "with an email and a subscriber" do
      it "should send the email to the subscriber" do
        expect(email_sender).to receive(:call)
          .with(
            address: email.address,
            subject: email.subject,
            body: email.body
          ).and_return(double(id: 0))

        Sidekiq::Testing.inline!
        described_class.perform_async(email.id)
      end
    end
  end

  describe ".perform_async_with_priority" do
    let(:email) { double(id: 0) }
    let(:priority) { nil }

    before do
      Sidekiq::Testing.fake!
      described_class.perform_async_with_priority(
        email.id, priority: priority
      )
    end

    context "with a low priority" do
      let(:priority) { :low }

      it "adds a worker to the low priority queue" do
        expect(Sidekiq::Queues["default"].size).to eq(1)
      end
    end

    context "with a high priority" do
      let(:priority) { :high }

      it "adds a worker to the high priority queue" do
        expect(Sidekiq::Queues["high_priority"].size).to eq(1)
      end
    end
  end
end

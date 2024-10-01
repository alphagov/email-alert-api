RSpec.describe SubscriberListMover do
  let(:list_1) { create :subscriber_list }
  let(:list_2) { create :subscriber_list }
  let(:email) { create :email }

  before do
    list_1.subscriptions << create_list(:subscription, 2)
    list_2.subscriptions << create_list(:subscription, 1)

    allow($stdout).to receive(:puts)
    allow(SendEmailJob).to receive(:perform_async_in_queue)
  end

  around(:each) do |example|
    ClimateControl.modify(BULK_MIGRATE_CONFIRMATION_EMAIL_ACCOUNT: "test@test.uk") do
      example.run
    end
  end

  describe "#with_send_email_false" do
    it "raises an error if from_slug does not exist" do
      expect { described_class.new(from_slug: "fake-list", to_slug: list_2.slug).call }
        .to raise_error(RuntimeError, "Source subscriber list fake-list does not exist")
    end

    it "raises an error if to_slug does not exist" do
      expect { described_class.new(from_slug: list_1.slug, to_slug: "fake-list-2").call }
        .to raise_error(RuntimeError, "Destination subscriber list fake-list-2 does not exist")
    end

    it "raises an error if there are no active subscriptions" do
      list_1.subscriptions = []

      expect { described_class.new(from_slug: list_1.slug, to_slug: list_2.slug).call }
        .to raise_error(RuntimeError, "No active subscriptions to move from #{list_1.slug}")
    end

    it "moves all subscriptions from the from_slug to the to_slug" do
      expect(list_2.subscriptions.count).to eq 1

      described_class.new(from_slug: list_1.slug, to_slug: list_2.slug).call

      expect(list_2.subscriptions.count).to eq 3
    end

    it "ends from_slug subscriptions with reason: bulk_migrated" do
      expect(list_1.subscriptions.count).to eq 2
      expect(list_1.subscriptions[1].ended_reason).to eq nil

      described_class.new(from_slug: list_1.slug, to_slug: list_2.slug).call

      expect(list_1.subscriptions.count).to eq 2
      expect(list_1.subscriptions[1].reload.ended_reason).to eq "bulk_migrated"
    end

    it "sends a confirmation email to an internal mailbox" do
      allow(BulkMigrateConfirmationEmailBuilder).to receive(:call).and_return(email)
      source_subscriber_list = SubscriberList.find_by(slug: list_1.slug)
      destination_subscriber_list = SubscriberList.find_by(slug: list_2.slug)

      expect(BulkMigrateConfirmationEmailBuilder)
      .to receive(:call)
      .with(source_id: source_subscriber_list.id,
            destination_id: destination_subscriber_list.id,
            count: 2)

      expect(SendEmailJob)
        .to receive(:perform_async_in_queue)
        .with(email.id, queue: :send_email_transactional)

      described_class.new(from_slug: list_1.slug, to_slug: list_2.slug).call
    end
  end

  describe "#with_send_email_true" do
    it "sends an email to all subscribers" do
      allow(BulkSubscriberListEmailBuilder).to receive(:call).and_return([1, 2])
      source_subscriber_list = SubscriberList.find_by(slug: list_1.slug)

      expect(BulkSubscriberListEmailBuilder)
      .to receive(:call)
      .with(subject: "Changes to GOV.UK emails",
            body: anything,
            subscriber_lists: source_subscriber_list)

      expect(SendEmailJob)
        .to receive(:perform_async_in_queue)
        .with(1, queue: :send_email_immediate)

      expect(SendEmailJob)
        .to receive(:perform_async_in_queue)
        .with(2, queue: :send_email_immediate)

      described_class.new(from_slug: list_1.slug, to_slug: list_2.slug, send_email: true).call
    end
  end
end

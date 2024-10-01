RSpec.describe BulkMigrateListJob do
  let!(:source_list) { create(:subscriber_list) }
  let!(:destination_list) { create(:subscriber_list) }

  let!(:source_list_subscribers) do
    create(:subscriber).tap do |subscriber|
      create(:subscription, subscriber:, subscriber_list: source_list)
    end
  end

  let!(:other_list_subscribers) do
    create(:subscriber).tap do |subscriber|
      other_list = create(:subscriber_list)
      create(:subscription, subscriber:, subscriber_list: other_list)
    end
  end

  describe "#perform" do
    around(:each) do |example|
      ClimateControl.modify(BULK_MIGRATE_CONFIRMATION_EMAIL_ACCOUNT: "test@test.uk") do
        example.run
      end
    end

    it "migrates subscribers from the source list to the successor list" do
      source_list_subscriber_id = source_list.subscribers.first.id

      described_class.new.perform(source_list.id, destination_list.id)

      expect(source_list.active_subscriptions_count).to be 0
      expect(source_list.subscriptions.last.ended_reason).to eq("bulk_migrated")

      expect(destination_list.subscriptions.count).to be 1
      expect(destination_list.subscribers.first.id).to eq source_list_subscriber_id
    end

    it "will not move subscribers from other lists" do
      expect { described_class.new.perform(source_list.id, destination_list.id) }.not_to(change { other_list_subscribers.ended_subscriptions.count })
    end

    it "queues a confirmation email when the migration is complete" do
      allow(SendEmailJob).to receive(:perform_async_in_queue)
      described_class.new.perform(source_list.id, destination_list.id)

      expect(Email.last.subject).to eq("Bulk migration of #{source_list.title} is complete")
      expect(SendEmailJob).to have_received(:perform_async_in_queue).with(Email.last.id, queue: :send_email_transactional)
    end
  end
end

RSpec.describe "bulk" do
  describe "email" do
    before do
      Rake::Task["bulk:email"].reenable
    end

    around(:each) do |example|
      ClimateControl.modify(SUBJECT: "subject", BODY: "body") do
        example.run
      end
    end

    it "builds emails for a subscriber list" do
      subscriber_list = create(:subscriber_list)

      expect(BulkSubscriberListEmailBuilder)
        .to receive(:call)
        .with(subject: "subject",
              body: "body",
              subscriber_lists: [subscriber_list])
        .and_call_original

      Rake::Task["bulk:email"].invoke(subscriber_list.id)
    end

    it "enqueues the emails for delivery" do
      subscriber_list = create(:subscriber_list)

      allow(BulkSubscriberListEmailBuilder).to receive(:call)
        .and_return([1, 2])

      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(1, queue: :delivery_immediate)

      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(2, queue: :delivery_immediate)

      Rake::Task["bulk:email"].invoke(subscriber_list.id)
    end
  end
end

RSpec.describe "bulk_email" do
  describe "for_lists" do
    before do
      Rake::Task["bulk_email:for_lists"].reenable
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

      Rake::Task["bulk_email:for_lists"].invoke(subscriber_list.id)
    end

    it "enqueues the emails for delivery" do
      subscriber_list = create(:subscriber_list)

      allow(BulkSubscriberListEmailBuilder).to receive(:call)
        .and_return([1, 2])

      expect(SendEmailWorker)
        .to receive(:perform_async_in_queue)
        .with(1, queue: :send_email_immediate)

      expect(SendEmailWorker)
        .to receive(:perform_async_in_queue)
        .with(2, queue: :send_email_immediate)

      Rake::Task["bulk_email:for_lists"].invoke(subscriber_list.id)
    end

    it "states how many emails are being sent, and to where" do
      subscriber_list1 = create(:subscriber_list)
      subscriber_list2 = create(:subscriber_list)
      allow(BulkSubscriberListEmailBuilder).to receive(:call)
        .and_return([1, 2, 3, 4, 5])

      expect { Rake::Task["bulk_email:for_lists"].invoke(subscriber_list1.id, subscriber_list2.id) }
        .to output(
          /Sending 5 emails to subscribers on the following lists: #{subscriber_list1.slug}, #{subscriber_list2.slug}/,
        ).to_stdout
    end
  end

  describe "temp_incident_new_subscribers" do
    before do
      Rake::Task["bulk_email:temp_incident_new_subscribers"].reenable
    end

    it "sends a single apology email to affected subscribers" do
      # affected subscriptions
      create(:subscription, created_at: Time.zone.local(2023, 2, 10, 14, 30), subscriber_list: create(:subscriber_list, :for_single_page_subscription)) # we can't differentiate between these and the incorrect subscriptions, so they are affected
      create(:subscription, created_at: Time.zone.local(2023, 3, 7, 14, 30), subscriber_list: create(:subscriber_list, content_id: SecureRandom.uuid)) # this is how we incorrectly subscribed users to affected alerts

      # same user has made multiple subscriptions, but will only get one email (not one per subscription)
      subscriber = create(:subscriber, address: "subscribed-twice@gov.uk")
      create(:subscription, created_at: Time.zone.local(2023, 3, 7, 14, 30), subscriber_list: create(:subscriber_list, content_id: SecureRandom.uuid), subscriber:)
      create(:subscription, created_at: Time.zone.local(2023, 3, 7, 14, 30), subscriber_list: create(:subscriber_list, content_id: SecureRandom.uuid), subscriber:)

      # unaffected subscriptions
      create(:subscription, created_at: Time.zone.local(2023, 1, 7, 14, 30), subscriber_list: create(:subscriber_list, :for_single_page_subscription)) # before the incident
      create(:subscription, created_at: Time.zone.local(2023, 4, 5, 14, 30), subscriber_list: create(:subscriber_list, :for_single_page_subscription)) # after the incident
      create(:subscription, created_at: Time.zone.local(2023, 3, 7, 14, 30), subscriber_list: create(:subscriber_list, :travel_advice)) # during incident but unaffected signup journey
      create(:subscription, created_at: Time.zone.local(2023, 3, 7, 14, 30), subscriber_list: create(:subscriber_list, :medical_safety_alert)) # during incident but unaffected signup journey

      expect(SendEmailWorker)
        .to receive(:perform_async_in_queue)
        .with(instance_of(String), queue: :send_email_immediate)
        .exactly(3).times

      expect { Rake::Task["bulk_email:temp_incident_new_subscribers"].invoke }
        .to change { Email.count }.by(3)

      apology_emails = Email.where(subject: "Action needed on email notifications")
      expect(apology_emails.first.body).to include("You recently signed up to")
    end
  end
end

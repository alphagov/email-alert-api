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
  end

  describe "temp_incident_new_subscribers" do
    let(:affected_subject) { "Confirm that you want to get emails from GOV.UK" }

    before do
      Rake::Task["bulk_email:temp_incident_new_subscribers"].reenable
    end

    it "sends a single apology email to affected subscribers" do
      # affected emails
      create(:email, subject: affected_subject, created_at: Time.zone.local(2021, 1, 7, 14, 35))
      create(:email, subject: affected_subject, created_at: Time.zone.local(2021, 1, 8, 13, 40))

      # unaffected emails
      create(:email, subject: affected_subject, created_at: Time.zone.local(2021, 1, 7, 14, 30))
      create(:email, subject: affected_subject, created_at: Time.zone.local(2021, 1, 8, 13, 50))
      create(:email, subject: "something else", created_at: Time.zone.local(2021, 1, 8, 13, 40))

      expect(SendEmailWorker)
        .to receive(:perform_async_in_queue)
        .with(instance_of(String), queue: :send_email_immediate)
        .once

      expect { Rake::Task["bulk_email:temp_incident_new_subscribers"].invoke }
        .to change { Email.count }.by(1)

      apology_emails = Email.where(subject: "Re: #{affected_subject}")
      expect(apology_emails.first.body).to include("please sign up again")
      expect(apology_emails.first.address).to eq(Email.pick(:address))
    end
  end
end

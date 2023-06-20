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

  describe "archived_specialist_topic_subscribers" do
    before do
      Rake::Task["bulk_email:archived_specialist_topic_subscribers"].reenable
    end

    it "is hardcoded to call the TopicListBulkUnsubscriber with 9 malformed archived specialist topic lists" do
      data = [
        {
          "list_slug" => "immigration-rules-4f0e641750",
          "redirect_title" => "Visas and immigration operational guidance",
          "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
        },
        {
          "list_slug" => "asylum-policy",
          "redirect_title" => "Visas and immigration operational guidance",
          "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
        },
        {
          "list_slug" => "fees-and-forms",
          "redirect_title" => "Visas and immigration operational guidance",
          "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
        },
        {
          "list_slug" => "nationality-guidance",
          "redirect_title" => "Visas and immigration operational guidance",
          "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
        },
        {
          "list_slug" => "entry-clearance-guidance",
          "redirect_title" => "Visas and immigration operational guidance",
          "redirect_url" => "government/collections/visas-and-immigration-operational-guidance",
        },
        {
          "list_slug" => "immigration-staff-guidance",
          "redirect_title" => "Immigration staff guidance",
          "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
        },
        {
          "list_slug" => "business-auditing-accounting-and-reporting-38e0c4ed05",
          "redirect_title" => "Accounting for UK companies",
          "redirect_url" => "/guidance/accounting-for-uk-companies",
        },
        {
          "list_slug" => "enforcement",
          "redirect_title" => "Visas and immigration operational guidance",
          "redirect_url" => "government/collections/visas-and-immigration-operational-guidance",
        },
        {
          "list_slug" => "windrush-caseworker-guidance",
          "redirect_title" => "Visas and immigration operational guidance",
          "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
        },
      ]

      data.each do |specialist_topic_data|
        expect(TopicListBulkUnsubscriber).to receive(:call).with(specialist_topic_data)
      end

      Rake::Task["bulk_email:archived_specialist_topic_subscribers"].invoke
    end
  end
end

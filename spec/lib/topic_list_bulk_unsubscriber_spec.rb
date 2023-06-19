RSpec.describe TopicListBulkUnsubscriber do
  describe ".call" do
    let(:subscriber_list_slug) { "archived_topic" }
    let(:redirect_title) { "Visas and immigration operational guidance" }
    let(:redirect_url) { "/government/collections/visas-and-immigration-operational-guidance" }
    let!(:subscriber_list) { create(:subscriber_list, slug: subscriber_list_slug, title: "Archived Topic") }
    let!(:subscription) { create(:subscription, subscriber_list:) }

    it "calls the BulkSubscriberListEmailBuilder and unsubscribes users" do
      expected_subject = "Update from GOV.UK for: #{subscriber_list.title}"
      expected_body = <<~BODY
        Update from GOV.UK for:
        #{subscriber_list.title}
        _________________________________________________________________
        You asked GOV.UK to email you when we add or update a page about:
        #{subscriber_list.title}
        This topic has been archived. You will not get any more emails about it.
        You can find more information about this topic at [#{redirect_title}](#{redirect_url}).
      BODY

      expect(BulkSubscriberListEmailBuilder)
        .to receive(:call)
        .with(subject: expected_subject,
              body: expected_body,
              subscriber_lists: [subscriber_list])
        .and_call_original

      information = {
        "list_slug" => subscriber_list_slug,
        "redirect_title" => redirect_title,
        "redirect_url" => redirect_url,
      }

      TopicListBulkUnsubscriber.call(information)
      expect(subscriber_list.subscriptions.last.ended_reason).to eq "bulk_unsubscribed"
    end
  end
end

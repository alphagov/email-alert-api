require 'gds_api/test_helpers/content_store'

RSpec.describe BulkUnsubscribeService do
  include ::GdsApi::TestHelpers::ContentStore

  let(:policy1_content_id) { SecureRandom.uuid }
  let(:policy2_content_id) { SecureRandom.uuid }

  let(:subscriber_list_with_single_subscriber) do
    create(:subscriber_list, links: { policies: [policy1_content_id] })
  end
  let(:subscriber_list_with_multiple_subscribers) do
    create(:subscriber_list, links: { policies: [policy2_content_id] })
  end

  let(:content_ids_and_replacements) do
    {
      policy1_content_id => create(:content_item, path: '/topic1'),
      policy2_content_id => create(:content_item, path: '/topic2')
    }
  end

  before :each do
    double_subscriber = create(
      :subscription,
      subscriber_list: subscriber_list_with_single_subscriber
    ).subscriber

    create(
      :subscription,
      subscriber: double_subscriber,
      subscriber_list: subscriber_list_with_multiple_subscribers
    )
    create(
      :subscription,
      subscriber_list: subscriber_list_with_multiple_subscribers
    )

    create(:subscriber, address: Email::COURTESY_EMAIL)

    content_ids_and_replacements.each do |(_content_id, content_item)|
      content_store_has_item(
        content_item.path,
        { 'title' => content_item.path.titleize }.to_json
      )
    end
  end

  describe ".call" do
    it "sends two emails" do
      Sidekiq::Testing.fake! do
        DeliveryRequestWorker.jobs.clear
        described_class.call(content_ids_and_replacements)
      end

      expect(DeliveryRequestWorker.jobs.size).to eq(2)
    end
  end
end

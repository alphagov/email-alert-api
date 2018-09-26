require 'gds_api/test_helpers/content_store'

RSpec.describe BulkUnsubscribeService do
  include ::GdsApi::TestHelpers::ContentStore

  describe 'send bulk emails' do
    before :each do

      policy_area1_content_id = SecureRandom.uuid
      policy_area2_content_id = SecureRandom.uuid

      policy_area1_subscriber_list = create(:subscriber_list, links: { policy_areas: [policy_area1_content_id] })
      policy_area2_subscriber_list = create(:subscriber_list, links: { policy_areas: [policy_area2_content_id] })


      @content_ids_and_replacements = {
            policy_area1_content_id => create(:content_item, path: '/topic1'),
            policy_area2_content_id => create(:content_item, path: '/topic2')
      }

      double_subscriber = create(
        :subscription,
        subscriber_list: policy_area1_subscriber_list
      ).subscriber

      create(
        :subscription,
        subscriber: double_subscriber,
        subscriber_list: policy_area2_subscriber_list
      )
      create(
        :subscription,
        subscriber_list: policy_area1_subscriber_list
      )

      create(:subscriber, address: Email::COURTESY_EMAIL)

      @content_ids_and_replacements.each do |(_content_id, content_item)|
        content_store_has_item(
          content_item.path,
          {
            'base_path' => content_item.path,
            'title' => content_item.path.titleize
          }.to_json
        )
      end
    end

    describe ".call" do
      it "sends three emails" do
        Sidekiq::Testing.fake! do
          DeliveryRequestWorker.jobs.clear
          described_class.call(@content_ids_and_replacements)
        end

        expect(DeliveryRequestWorker.jobs.size).to eq(3)
      end
    end
  end

  describe 'redirect to announcements finder' do
    before :each do
      @policy_area1_content_id = SecureRandom.uuid

      @content_ids_and_replacements = {
          @policy_area1_content_id => build(:content_item, path: '/topic1'),
      }
      content_store_has_item(
        '/topic1',
          {
              'base_path' => '/topic1',
              'title' => 'topic1'
          }.to_json
      )
    end

    it 'sends the user to the announcements' do
      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: 'announcements',
             links: { policy_areas: [@policy_area1_content_id] })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include('/government/announcements')))
      BulkUnsubscribeService.call(@content_ids_and_replacements)
    end

    it 'sends the user to the publications' do
      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: 'publications',
             links: { policy_areas: [@policy_area1_content_id] })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include('/government/publications')))
      BulkUnsubscribeService.call(@content_ids_and_replacements)
    end

    it 'sends the user to a url filtered on people' do
      person_content_id = SecureRandom.uuid

      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: 'announcements',
             links: { policy_areas: [@policy_area1_content_id], people: [person_content_id] })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include('people%5B%5D=person-slug')))

      BulkUnsubscribeService.call(@content_ids_and_replacements,
                                  people: [{ content_id: person_content_id, slug: 'person-slug' }])
    end

    it 'sends the user to a url filtered on world location' do
      world_location_id = SecureRandom.uuid

      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: 'announcements',
             links: { policy_areas: [@policy_area1_content_id], world_locations: [world_location_id] })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include('world_locations%5B%5D=world_location_slug')))

      BulkUnsubscribeService.call(@content_ids_and_replacements,
                                  world_locations: [{ content_id: world_location_id, slug: 'world_location_slug' }])
    end

    it 'sends the user to a url filtered on department (organisation)' do
      organisations_id = SecureRandom.uuid

      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: 'publications',
             links: { policy_areas: [@policy_area1_content_id], organisations: [organisations_id] })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include('departments%5B%5D=organisation_slug')))

      BulkUnsubscribeService.call(@content_ids_and_replacements,
                                  organisations: [{ content_id: organisations_id, slug: 'organisation_slug' }])
    end

    describe 'taxon and subtaxon' do
      before :each do
        create(:subscriber_list_with_subscribers,
               subscriber_count: 1,
               email_document_supertype: 'publications',
               links: { policy_areas: [@policy_area1_content_id] })

        Redis.current = double
        taxonomy = [{
                      content_id: 'level_one_content_id',
                      base_path: '/level_one',
                      links: {
                        child_taxons: [
                          {
                            content_id: 'level_two_content_id',
                            base_path: '/level_one/level_two'
                          }
                        ]
                      }
                    }]
        allow(Redis.current).to receive(:get).with('topic_taxonomy_taxons').and_return(JSON.dump(taxonomy))
      end
      it 'sends the user to a url filtered on taxon and subtaxon' do
        expect(DeliveryRequestService).to receive(:call).
            with(email: having_attributes(body: include('taxons%5B%5D=level_one_content_id', 'subtaxons%5B%5D=level_two_content_id')))

        BulkUnsubscribeService.call(@content_ids_and_replacements,
                                    policy_area_mappings: [{ content_id: @policy_area1_content_id, taxon_path: '/level_one/level_two' }])
      end
      it 'sends the user to a url filtered on taxon; the subtaxon is set to "all"' do
        expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include('taxons%5B%5D=level_one_content_id', 'subtaxons%5B%5D=all')))

        BulkUnsubscribeService.call(@content_ids_and_replacements,
                                    policy_area_mappings: [{ content_id: @policy_area1_content_id, taxon_path: '/level_one' }])
      end
    end
  end
end

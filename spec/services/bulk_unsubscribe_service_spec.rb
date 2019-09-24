require "gds_api/test_helpers/content_store"

RSpec.describe BulkUnsubscribeService do
  include ::GdsApi::TestHelpers::ContentStore

  def content_store_has_data(policy_area_mappings)
    policy_area_mappings.each do |hash|
      content_store_has_item(
        hash[:taxon_path],
        {
          "base_path" => hash[:taxon_path],
          "title" => hash[:taxon_path].titleize,
        }.to_json,
      )
      content_store_has_item(
        hash[:policy_area_path],
        {
          "base_path" => hash[:policy_area_path],
          "title" => hash[:policy_area_path].titleize,
        }.to_json,
      )
    end
  end

  describe "send bulk emails" do
    before :each do
      Redis.current = double
      allow(Redis.current).to receive(:get).with("topic_taxonomy_taxons").and_return(JSON.dump([]))

      policy_area1_content_id = SecureRandom.uuid
      policy_area2_content_id = SecureRandom.uuid

      policy_area1_subscriber_list = create(:subscriber_list, links: { policy_areas: { any: [policy_area1_content_id] } })
      policy_area2_subscriber_list = create(:subscriber_list, links: { policy_areas: { any: [policy_area2_content_id] } })

      @policy_area_mappings = [
        { content_id: policy_area1_content_id, taxon_path: "/topic1", policy_area_path: "/policy1" },
        { content_id: policy_area2_content_id, taxon_path: "/topic2", policy_area_path: "/policy2" },
      ]

      double_subscriber = create(
        :subscription,
        subscriber_list: policy_area1_subscriber_list,
      ).subscriber

      create(
        :subscription,
        subscriber: double_subscriber,
        subscriber_list: policy_area2_subscriber_list,
      )
      create(
        :subscription,
        subscriber_list: policy_area1_subscriber_list,
      )

      create(:subscriber, address: Email::COURTESY_EMAIL)

      content_store_has_data(@policy_area_mappings)
    end

    describe ".call" do
      it "sends three emails" do
        Sidekiq::Testing.fake! do
          DeliveryRequestWorker.jobs.clear
          BulkUnsubscribeService.call(policy_area_mappings: @policy_area_mappings)
        end

        expect(DeliveryRequestWorker.jobs.size).to eq(3)
      end
    end
  end

  describe "redirect to announcements finder" do
    before :each do
      Redis.current = double
      allow(Redis.current).to receive(:get).with("topic_taxonomy_taxons").and_return(JSON.dump([]))

      @policy_area1_content_id = SecureRandom.uuid

      @policy_area_mappings = [
          content_id: @policy_area1_content_id, taxon_path: "/level_one", policy_area_path: "/policy1",
      ]
      content_store_has_data(@policy_area_mappings)
    end

    it "sends the user to the announcements" do
      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: "announcements",
             links: { policy_areas: { any: [@policy_area1_content_id] } })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include("/government/announcements")))
      BulkUnsubscribeService.call(policy_area_mappings: @policy_area_mappings)
    end

    it "sends the user to the publications" do
      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: "publications",
             links: { policy_areas: { any: [@policy_area1_content_id] } })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include("/government/publications")))
      BulkUnsubscribeService.call(policy_area_mappings: @policy_area_mappings)
    end

    it "sends the user to a url filtered on people" do
      person_content_id = SecureRandom.uuid

      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: "announcements",
             links: { policy_areas: { any: [@policy_area1_content_id] }, people: { any: [person_content_id] } })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include("people%5B%5D=person-slug")))

      BulkUnsubscribeService.call(policy_area_mappings: @policy_area_mappings,
                                  people: [{ content_id: person_content_id, slug: "person-slug" }])
    end

    it "sends the user to a url filtered on world location" do
      world_location_id = SecureRandom.uuid

      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: "announcements",
             links: { policy_areas: { any: [@policy_area1_content_id] }, world_locations: { any: [world_location_id] } })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include("world_locations%5B%5D=world_location_slug")))

      BulkUnsubscribeService.call(policy_area_mappings: @policy_area_mappings,
                                  world_locations: [{ content_id: world_location_id, slug: "world_location_slug" }])
    end

    it "sends the user to a url filtered on department (organisation)" do
      organisations_id = SecureRandom.uuid

      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: "publications",
             links: { policy_areas: { any: [@policy_area1_content_id] }, organisations: { any: [organisations_id] } })

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include("departments%5B%5D=organisation_slug")))

      BulkUnsubscribeService.call(policy_area_mappings: @policy_area_mappings,
                                  organisations: [{ content_id: organisations_id, slug: "organisation_slug" }])
    end
  end

  describe "Title swap" do
    it "swaps the policy area title with the taxon title" do
      @policy_area_content_id = SecureRandom.uuid

      Redis.current = double
      allow(Redis.current).to receive(:get).with("topic_taxonomy_taxons").and_return(JSON.dump([]))

      content_store_has_item(
        "/taxon",
        {
          "base_path" => "/taxon",
          "title" => "taxon_title",
        }.to_json,
      )
      content_store_has_item(
        "/policy_area",
        {
          "base_path" => "/policy_area",
          "title" => "policy_title",
        }.to_json,
      )

      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: "publications",
             title: "this is about a policy_title amongst other things",
             links: { policy_areas: { any: [@policy_area_content_id] } })

      policy_area_mappings = [{ content_id: @policy_area_content_id,
                                taxon_path: "/taxon",
                                policy_area_path: "/policy_area" }]

      expect(DeliveryRequestService).to receive(:call).
        with(email: having_attributes(body: include("this is about a taxon_title amongst other things")))

      BulkUnsubscribeService.call(policy_area_mappings: policy_area_mappings)
    end
  end

  describe "taxon and subtaxon" do
    before :each do
      @policy_area_content_id = SecureRandom.uuid

      create(:subscriber_list_with_subscribers,
             subscriber_count: 1,
             email_document_supertype: "publications",
             links: { policy_areas: { any: [@policy_area_content_id] } })

      taxonomy = [{
                    content_id: "level_one_content_id",
                    base_path: "/level_one",
                    links: {
                      child_taxons: [
                        {
                          content_id: "level_two_content_id",
                          base_path: "/level_one/level_two",
                        },
                      ],
                    },
                  }]
      Redis.current = double
      allow(Redis.current).to receive(:get).with("topic_taxonomy_taxons").and_return(JSON.dump(taxonomy))
    end
    it "sends the user to a url filtered on taxon and subtaxon" do
      policy_area_mappings = [{ content_id: @policy_area_content_id,
                                taxon_path: "/level_one/level_two",
                                policy_area_path: "/policy1" }]
      content_store_has_data(policy_area_mappings)

      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include("taxons%5B%5D=level_one_content_id", "subtaxons%5B%5D=level_two_content_id")))

      BulkUnsubscribeService.call(policy_area_mappings: policy_area_mappings)
    end
    it 'sends the user to a url filtered on taxon; the subtaxon is set to "all"' do
      policy_area_mappings = [{ content_id: @policy_area_content_id,
                                taxon_path: "/level_one",
                                policy_area_path: "/policy1" }]
      content_store_has_data(policy_area_mappings)

      expect(DeliveryRequestService).to receive(:call).
        with(email: having_attributes(body: include("taxons%5B%5D=level_one_content_id", "subtaxons%5B%5D=all")))

      BulkUnsubscribeService.call(policy_area_mappings: policy_area_mappings)
    end
  end
end

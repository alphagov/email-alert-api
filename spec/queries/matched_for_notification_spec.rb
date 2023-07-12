RSpec.describe MatchedForNotification do
  describe "#call" do
    before do
      @subscriber_list_that_should_never_match = create(
        :subscriber_list,
        tags: {
          topics: { any: %w[Badical-Turbo-Radness] }, format: { any: %w[news_story] }
        },
      )
    end

    def create_subscriber_list_with_tags_facets(facets)
      create(:subscriber_list, tags: facets)
    end

    def create_subscriber_list_with_links_facets(facets)
      create(:subscriber_list, links: facets)
    end

    def execute_query(query_hash, field: :tags)
      described_class.new(query_field: field).call(query_hash)
    end

    context "subscriber_lists match on tag and links keys" do
      before do
        @lists = {
          tags:
            {
              any_topic_paye_any_format_guides: create_subscriber_list_with_tags_facets(topics: { any: %w[paye] }, format: { any: %w[policy guide] }),
              any_topic_vat_licensing: create_subscriber_list_with_tags_facets(topics: { any: %w[vat licensing] }),
            },
          links:
            {
              any_topic_paye_any_format_guides: create_subscriber_list_with_links_facets(topics: { any: %w[paye] }, format: { any: %w[policy guide] }),
              any_topic_vat_licensing: create_subscriber_list_with_links_facets(topics: { any: %w[vat licensing] }),
            },
        }
      end

      %i[links tags].each do |key|
        it "finds subscriber lists where at least one value of each #{key} in the subscription is present in the query_hash" do
          lists = execute_query({ topics: %w[paye], format: %w[guide] }, field: key)
          expect(lists).to eq([@lists[key][:any_topic_paye_any_format_guides]])

          lists = execute_query({ topics: %w[paye], format: %w[guide] }, field: key)
          expect(lists).to eq([@lists[key][:any_topic_paye_any_format_guides]])

          lists = execute_query({ topics: %w[vat] }, field: key)
          expect(lists).to eq([@lists[key][:any_topic_vat_licensing]])

          lists = execute_query({ topics: %w[licensing] }, field: key)
          expect(lists).to eq([@lists[key][:any_topic_vat_licensing]])
        end
      end
    end

    context "matches on all topics" do
      before do
        @all_topics_tax_vat = create_subscriber_list_with_tags_facets(topics: { all: %w[vat tax] })
        @all_topics_tax_vat_licensing = create_subscriber_list_with_tags_facets(topics: { all: %w[vat tax licensing] })
      end

      it "finds subscriber lists matching all topics" do
        lists = execute_query({ topics: %w[vat tax] })
        expect(lists).to eq([@all_topics_tax_vat])
      end
    end

    context "matches on any and all topics" do
      before do
        @all_topics_tax_vat_any_topics_licensing_paye = create_subscriber_list_with_tags_facets(topics: { all: %w[vat tax], any: %w[licensing paye] })
        @all_topics_tax_vat_licensing_any_topics_paye = create_subscriber_list_with_tags_facets(topics: { all: %w[vat tax schools], any: %w[paye] })
      end

      it "finds subscriber lists matching on both of all and one of any topics" do
        lists = execute_query({ topics: %w[vat tax licensing] })
        expect(lists).to eq([@all_topics_tax_vat_any_topics_licensing_paye])
      end

      it "does not find subscriber list for mixture of all and any topics when not all topics present" do
        lists = execute_query({ field: :links, query_hash: { topics: %w[vat licensing] } })
        expect(lists).not_to include(@all_topics_tax_vat_any_topics_licensing_paye)
      end
    end

    context "matches on all topics and any policies" do
      before do
        @all_topics_tax_vat_any_policies_economy_industry = create_subscriber_list_with_tags_facets(topics: { all: %w[vat tax] }, policies: { any: %w[economy industry] })
        @all_topics_vat_any_policies_economy_industry = create_subscriber_list_with_tags_facets(topics: { all: %w[paye schools] }, policies: { any: %w[economy industry] })
      end

      it "finds subscriber lists matching a mix of all topics and any policies" do
        lists = execute_query({ topics: %w[vat tax], policies: %w[economy industry] })
        expect(lists).to eq([@all_topics_tax_vat_any_policies_economy_industry])
      end

      it "does not find subscriber list for mix of all topics and any policies when not all topics present" do
        lists = execute_query({ field: :links, query_hash: { topics: %w[vat], policies: %w[economy] } })
        expect(lists).not_to include(@all_topics_tax_vat_any_policies_economy_industry)
      end
    end

    context "matches on all topics and all policies" do
      before do
        @all_topics_tax_vat = create_subscriber_list_with_tags_facets(topics: { all: %w[vat tax] })
        @all_topics_tax_vat_all_policies_economy_industry = create_subscriber_list_with_tags_facets(topics: { all: %w[vat tax] }, policies: { all: %w[economy industry] })
        @all_topics_vat_policies_economy_industry = create_subscriber_list_with_tags_facets(topics: { all: %w[paye schools] }, policies: { all: %w[economy broadband] })
      end

      it "finds subscriber lists matching a mix of all topics and policies" do
        lists = execute_query({ topics: %w[vat tax licensing], policies: %w[economy industry] })
        expect(lists).to include(@all_topics_tax_vat_all_policies_economy_industry)
      end

      it "does not find subscriber list for all topics when not all topics present" do
        lists = execute_query({ topics: %w[vat schools] })
        expect(lists).not_to include(@all_topics_tax_vat)
      end

      it "does not find subscriber list for mix of all topics and policies when not all policies present" do
        lists = execute_query({ topics: %w[vat tax ufos], policies: %w[economy acceptable_footwear] })
        expect(lists).to_not include(@all_topics_tax_vat_all_policies_economy_schools)
      end
    end

    context "there are other, non-matching link types in the query hash" do
      before do
        @topics_any_licensing = create_subscriber_list_with_tags_facets(topics: { any: %w[licensing] })
      end

      it "finds lists where all the link types in the subscription have a value present" do
        lists = execute_query({ topics: %w[licensing], another_link_thats_not_part_of_the_subscription: %w[elephants] })
        expect(lists).to eq([@topics_any_licensing])
      end
    end

    context "there are non-matching values in the query_hash" do
      before do
        @topics_any_licensing = create_subscriber_list_with_tags_facets(topics: { any: %w[licensing] })
      end

      it "finds lists where all the link types in the subscription have a value present" do
        lists = execute_query({ topics: %w[licensing elephants] })
        expect(lists).to eq([@topics_any_licensing])
      end

      it "doesn't return lists which have no tag types present in the document" do
        lists = execute_query({ another_tag_thats_not_part_of_any_subscription: %w[elephants] })
        expect(lists).to eq([])
      end
    end

    context "matches on content_store_document_type" do
      let!(:list1) { create(:subscriber_list, links: { content_store_document_type: { any: %w[press_release] } }) }
      let!(:list2) { create(:subscriber_list, links: { content_store_document_type: { any: %w[other_type] } }) }

      it "finds subscriber lists matching content_store_document_type" do
        lists = execute_query({ content_store_document_type: "press_release" }, field: :links)
        expect(lists).to eq([list1])
      end
    end

    context "Specialist publisher edge case in format tag" do
      before do
        @subscriber_list = create_subscriber_list_with_tags_facets(format: { any: %w[employment_tribunal_decision] })
      end

      it "finds the list when the criteria values is a string that is present in the subscriber list values for the field" do
        lists = execute_query({ format: "employment_tribunal_decision" })
        expect(lists).to eq([@subscriber_list])
      end

      it "does not find the list when the criteria values is a string that is not present in the subscriber list values for the field" do
        lists = execute_query({ format: "drug_safety_update" })
        expect(lists).to eq([])
      end
    end
  end
end

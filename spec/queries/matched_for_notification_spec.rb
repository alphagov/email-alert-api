RSpec.describe MatchedForNotification do
  describe "#call" do
    before do
      @subscriber_list_that_should_never_match = create(
        :subscriber_list,
        tags: {
          tribunal_decision_categories: { any: %w[jurisdictional-points] }, format: { any: %w[news_story] }
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
              any_category_tax_any_format_guides: create_subscriber_list_with_tags_facets(tribunal_decision_categories: { any: %w[tax] }, format: { any: %w[policy guide] }),
              any_category_pension_harassment: create_subscriber_list_with_tags_facets(tribunal_decision_categories: { any: %w[pension harassment] }),
            },
          links:
            {
              any_category_tax_any_format_guides: create_subscriber_list_with_links_facets(taxon_tree: { any: %w[uuid-001] }, format: { any: %w[policy guide] }),
              any_category_pension_harassment: create_subscriber_list_with_links_facets(taxon_tree: { any: %w[uuid-002 uuid-003] }),
            },
        }
      end

      it "finds subscriber lists where at least one value of each link in the subscription is present in the query_hash" do
        lists = execute_query({ taxon_tree: %w[uuid-001], format: %w[guide] }, field: :links)
        expect(lists).to eq([@lists[:links][:any_category_tax_any_format_guides]])

        lists = execute_query({ taxon_tree: %w[uuid-001], format: %w[guide] }, field: :links)
        expect(lists).to eq([@lists[:links][:any_category_tax_any_format_guides]])

        lists = execute_query({ taxon_tree: %w[uuid-002] }, field: :links)
        expect(lists).to eq([@lists[:links][:any_category_pension_harassment]])

        lists = execute_query({ taxon_tree: %w[uuid-003] }, field: :links)
        expect(lists).to eq([@lists[:links][:any_category_pension_harassment]])
      end

      it "finds subscriber lists where at least one value of each tag in the subscription is present in the query_hash" do
        lists = execute_query({ tribunal_decision_categories: %w[tax], format: %w[guide] }, field: :tags)
        expect(lists).to eq([@lists[:tags][:any_category_tax_any_format_guides]])

        lists = execute_query({ tribunal_decision_categories: %w[tax], format: %w[guide] }, field: :tags)
        expect(lists).to eq([@lists[:tags][:any_category_tax_any_format_guides]])

        lists = execute_query({ tribunal_decision_categories: %w[pension] }, field: :tags)
        expect(lists).to eq([@lists[:tags][:any_category_pension_harassment]])

        lists = execute_query({ tribunal_decision_categories: %w[harassment] }, field: :tags)
        expect(lists).to eq([@lists[:tags][:any_category_pension_harassment]])
      end
    end

    context "matches on all tribunal decision categories" do
      before do
        @all_categories_tax_pension = create_subscriber_list_with_tags_facets(tribunal_decision_categories: { all: %w[pension tax] })
        @all_categories_tax_pension_harassment = create_subscriber_list_with_tags_facets(tribunal_decision_categories: { all: %w[pension tax harassment] })
      end

      it "finds subscriber lists matching all tribunal decision categories" do
        lists = execute_query({ tribunal_decision_categories: %w[pension tax] })
        expect(lists).to eq([@all_categories_tax_pension])
      end
    end

    context "matches on any and all tribunal decision categories" do
      before do
        @all_categories_tax_pension_any_categories_harassment_tax = create_subscriber_list_with_tags_facets(tribunal_decision_categories: { all: %w[pension tax], any: %w[harassment tax] })
        @all_categories_tax_pension_harassment_any_categories_tax = create_subscriber_list_with_tags_facets(tribunal_decision_categories: { all: %w[pension tax renumeration], any: %w[tax] })
      end

      it "finds subscriber lists matching on both of all and one of any tribunal decision categories" do
        lists = execute_query({ tribunal_decision_categories: %w[pension tax harassment] })
        expect(lists).to eq([@all_categories_tax_pension_any_categories_harassment_tax])
      end

      it "does not find subscriber list for mixture of all and any tribunal decision categories when not all tribunal decision categories present" do
        lists = execute_query({ field: :links, query_hash: { tribunal_decision_categories: %w[pension harassment] } })
        expect(lists).not_to include(@all_categories_tax_pension_any_categories_harassment_tax)
      end
    end

    context "matches on all tribunal decision judges and any tribunal decision categories" do
      before do
        @all_judges_tax_pension_any_categories_redundancy_protective_award =
          create_subscriber_list_with_tags_facets(tribunal_decision_judges: { all: %w[pension tax] }, tribunal_decision_categories: { any: %w[redundancy protective-award] })
        @all_judges_pension_any_categories_redundancy_protective_award =
          create_subscriber_list_with_tags_facets(tribunal_decision_judges: { all: %w[tax renumeration] }, tribunal_decision_categories: { any: %w[redundancy protective-award] })
      end

      it "finds subscriber lists matching a mix of all tribunal decision judges and any tribunal decision categories" do
        lists = execute_query({ tribunal_decision_judges: %w[pension tax], tribunal_decision_categories: %w[redundancy protective-award] })
        expect(lists).to eq([@all_judges_tax_pension_any_categories_redundancy_protective_award])
      end

      it "does not find subscriber list for mix of all tribunal decision judges and any tribunal decision categories when not all tribunal decision judges present" do
        lists = execute_query({ field: :links, query_hash: { tribunal_decision_judges: %w[pension], tribunal_decision_categories: %w[redundancy] } })
        expect(lists).not_to include(@all_judges_tax_pension_any_categories_redundancy_protective_award)
      end
    end

    context "matches on all tribunal decision judges and all tribunal decision categories" do
      before do
        @all_judges_tax_pension = create_subscriber_list_with_tags_facets(tribunal_decision_judges: { all: %w[pension tax] })
        @all_judges_tax_pension_all_categories_redundancy_protective_award = create_subscriber_list_with_tags_facets(tribunal_decision_judges: { all: %w[pension tax] }, tribunal_decision_categories: { all: %w[redundancy protective-award] })
        @all_judges_pension_tribunal_decision_categories_redundancy_protective_award = create_subscriber_list_with_tags_facets(tribunal_decision_judges: { all: %w[tax renumeration] }, tribunal_decision_categories: { all: %w[redundancy broadband] })
      end

      it "finds subscriber lists matching a mix of all tribunal decision judges and tribunal decision categories" do
        lists = execute_query({ tribunal_decision_judges: %w[pension tax harassment], tribunal_decision_categories: %w[redundancy protective-award] })
        expect(lists).to include(@all_judges_tax_pension_all_categories_redundancy_protective_award)
      end

      it "does not find subscriber list for all tribunal decision judges when not all tribunal decision judges present" do
        lists = execute_query({ tribunal_decision_judges: %w[pension renumeration] })
        expect(lists).not_to include(@all_judges_tax_pension)
      end

      it "does not find subscriber list for mix of all tribunal decision judges and tribunal decision categories when not all tribunal decision categories present" do
        lists = execute_query({ tribunal_decision_judges: %w[pension tax ufos], tribunal_decision_categories: %w[redundancy acceptable_footwear] })
        expect(lists).to_not include(@all_judges_tax_pension_all_categories_redundancy_renumeration)
      end
    end

    context "there are other, non-matching link types in the query hash" do
      before do
        @tribunal_decision_categories_any_harassment = create_subscriber_list_with_tags_facets(tribunal_decision_categories: { any: %w[harassment] })
      end

      it "finds lists where all the link types in the subscription have a value present" do
        lists = execute_query({ tribunal_decision_categories: %w[harassment], another_link_thats_not_part_of_the_subscription: %w[practice-and-procedure-issues] })
        expect(lists).to eq([@tribunal_decision_categories_any_harassment])
      end
    end

    context "there are non-matching values in the query_hash" do
      before do
        @tribunal_decision_categories_any_harassment = create_subscriber_list_with_tags_facets(tribunal_decision_categories: { any: %w[harassment] })
      end

      it "finds lists where all the link types in the subscription have a value present" do
        lists = execute_query({ tribunal_decision_categories: %w[harassment practice-and-procedure-issues] })
        expect(lists).to eq([@tribunal_decision_categories_any_harassment])
      end

      it "doesn't return lists which have no tag types present in the document" do
        lists = execute_query({ another_tag_thats_not_part_of_any_subscription: %w[practice-and-procedure-issues] })
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

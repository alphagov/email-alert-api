require 'rails_helper'

RSpec.describe SubscriberListQuery do
  describe ".at_least_one_topic_value_matches" do
    before do
      @list1 = create(:subscriber_list, tags: { format: ["raib_report"], })
      @list2 = create(:subscriber_list, tags: { topics: ["environmental-management/boating"], })
      @list3 = create(:subscriber_list, tags: {
        topics: [
          "environmental-management/boating",
          "environmental-management/sailing" ,
          "environmental-management/swimming"
        ],
      })
    end

    it "finds lists where at least one value is in the topic tags" do
      expect(SubscriberListQuery.new.at_least_one_topic_value_matches(
        'environmental-management/boating'
      )).to eq [@list2, @list3]
    end
  end

  describe "#where_all_links_match_at_least_one_value_in(query_hash)" do
    before do
      @list1 = create(:subscriber_list, tags: {
        topics: ["oil-and-gas/licensing"], organisations: ["environment-agency", "hm-revenue-customs"]
      })

      @list2 = create(:subscriber_list, tags: {
        topics: ["business-tax/vat", "oil-and-gas/licensing"]
      })

      @list3 = create(:subscriber_list, links: { topics: ["uuid-123"], policies: ["uuid-888"] })

      @list4 = create(:subscriber_list,
        links: { topics: ["uuid-123"] },
        tags: {
          topics: ["environmental-management/boating"],
        }
      )
    end

    def execute_query(field:, query_hash:)
      SubscriberListQuery.new(query_field: field).where_all_links_match_at_least_one_value_in(query_hash)
    end

    it "finds subscriber lists where at least one value of each link in the subscription is present in the query_hash" do
      lists = execute_query(field: :tags, query_hash: { topics: ["oil-and-gas/licensing"] })
      expect(lists).to eq([@list2])

      lists = execute_query(field: :tags, query_hash: { topics: ["business-tax/vat"] })
      expect(lists).to eq([@list2])

      lists = execute_query(field: :tags, query_hash: {
        topics: ["oil-and-gas/licensing"], organisations: ["environment-agency"]
      })
      expect(lists).to eq([@list1, @list2])

      lists = execute_query(field: :links, query_hash: {topics: ["uuid-123"], policies: ["uuid-888"]})
      expect(lists).to eq([@list3, @list4])

      lists = execute_query(field: :links, query_hash: {topics: ["uuid-123"]})
      expect(lists).to eq([@list4])
    end

    context "there are other, non-matching link types in the query hash" do
      let(:lists) do
        execute_query(field: :tags, query_hash: {
          topics: ["oil-and-gas/licensing"],
          another_link_thats_not_part_of_the_subscription: ["elephants"],
        })
      end

      it "finds lists where all the link types in the subscription have a value present" do
        expect(lists).to eq([@list2])
      end
    end

    context "there are non-matching values in the query_hash" do
      let(:lists) {
        execute_query(field: :tags, query_hash: {
          topics: ["oil-and-gas/licensing", "elephants"],
        })
      }

      it "finds lists where all the link types in the subscription have a value present" do
        expect(lists).to eq([@list2])
      end
    end

    it "doesn't return lists which have no tag types present in the document" do
      lists = execute_query(field: :tags, query_hash: {
        another_tag_thats_not_part_of_any_subscription: ["elephants"],
      })
      expect(lists).to eq([])
    end
  end

  describe "#find_exact_match_with(links:, tags:)" do
    before do
      @list_with_tags = create(
        :subscriber_list,
        tags: {
          topics: ["oil-and-gas/licensing"],
          organisations: ["environment-agency", "hm-revenue-customs"]
        },
        document_type: "policy",
      )
    end

    it "requires all tag types in the document to be present in the list" do
      found_lists = SubscriberListQuery.new(query_field: :tags)
        .find_exact_match_with({ topics: ["oil-and-gas/licensing"] }, "policy")
      expect(found_lists).to eq([])
    end

    it "requires all tag types in the list to be present in the document" do
      found_lists = SubscriberListQuery.new(query_field: :tags)
        .find_exact_match_with({
          topics: ["oil-and-gas/licensing"],
          organisations: ["environment-agency", "hm-revenue-customs"],
          foo: ["bar"]
        }, "policy")
      expect(found_lists).to eq([])
    end

    it "requires the a match on the document type" do
      found_lists = SubscriberListQuery.new(query_field: :tags)
        .find_exact_match_with({
          topics: ["oil-and-gas/licensing"],
          organisations: ["environment-agency", "hm-revenue-customs"]
        }, "something_else")
      expect(found_lists).to eq([])
    end

    it "requires all tag types in the list to be present in the document" do
      list_with_links = create(
        :subscriber_list,
        links: { topics: ["uuid-888"] },
        document_type: "policy",
      )

      found_by_tags = SubscriberListQuery.new(query_field: :tags)
        .find_exact_match_with({
          topics: ["oil-and-gas/licensing"],
          organisations: ["environment-agency", "hm-revenue-customs"]
        }, "policy")

      expect(found_by_tags).to eq([@list_with_tags])

      found_by_links = SubscriberListQuery.new(query_field: :links)
        .find_exact_match_with({
          topics: ["uuid-888"]
        }, "policy")

      expect(found_by_links).to eq([list_with_links])
    end
  end
end

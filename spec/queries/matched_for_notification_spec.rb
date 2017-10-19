require 'rails_helper'

RSpec.describe MatchedForNotification do
  describe "#call" do
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
        })
    end

    def execute_query(field:, query_hash:)
      described_class.new(query_field: field).call(query_hash)
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

      lists = execute_query(field: :links, query_hash: { topics: ["uuid-123"], policies: ["uuid-888"] })
      expect(lists).to eq([@list3, @list4])

      lists = execute_query(field: :links, query_hash: { topics: ["uuid-123"] })
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

    context "Specialist publisher edge case" do
      let!(:subscriber_list) { create(:subscriber_list, tags: { format: ["employment_tribunal_decision"] }) }

      it "finds the list when the criteria values is a string that is present in the subscriber list values for the field" do
        lists = execute_query(field: :tags, query_hash: {
          format: "employment_tribunal_decision",
        })

        expect(lists).to eq([subscriber_list])
      end

      it "does not find the list when the criteria values is a string that is not present in the subscriber list values for the field" do
        lists = execute_query(field: :tags, query_hash: {
          format: "drug_safety_update",
        })

        expect(lists).to eq([])
      end
    end

    it "doesn't return lists which have no tag types present in the document" do
      lists = execute_query(field: :tags, query_hash: {
        another_tag_thats_not_part_of_any_subscription: ["elephants"],
      })
      expect(lists).to eq([])
    end
  end
end

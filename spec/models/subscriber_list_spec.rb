require "rails_helper"

RSpec.describe SubscriberList, type: :model do

  describe "scopes" do

    before do
      @list1 = create(:subscriber_list, tags: {
        format: ["raib_report"],
      })
      @list2 = create(:subscriber_list, tags: {
        topics: ["environmental-management/boating"],
      })
      @list3 = create(:subscriber_list, tags: {
        topics: ["environmental-management/boating", "environmental-management/sailing" , "environmental-management/swimming"],
      })
    end

    describe ".with_at_least_one_topic_value" do
      it "finds lists where at least one value is in the topic tags" do
        expect(SubscriberList.with_at_least_one_topic_value('environmental-management/boating')).to eq [@list2, @list3]
      end
    end
  end

  describe ".find_with_at_least_one_tag_of_each_type" do
    before do
      @list1 = create(:subscriber_list, tags: {
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency", "hm-revenue-customs"]
      })

      @list2 = create(:subscriber_list, tags: {
        topics: ["business-tax/vat", "oil-and-gas/licensing"]
      })

      create(:subscriber_list, tags: {
        topics: ["environmental-management/boating"],
      })
    end

    it "finds lists where at least one value of each tag in the subscription is present in the document" do
      lists = SubscriberList.with_at_least_one_tag_of_each_type(tags: {
        topics: ["oil-and-gas/licensing"]
      })
      expect(lists).to eq([@list2])

      lists = SubscriberList.with_at_least_one_tag_of_each_type(tags: {
        topics: ["business-tax/vat"],
      })
      expect(lists).to eq([@list2])

      lists = SubscriberList.with_at_least_one_tag_of_each_type(tags: {
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency"]
      })
      expect(lists.to_set).to eq([@list1, @list2].to_set)
    end

    it "finds lists where all the tag types in the subscription have a value present, even those there are other tag types in the document" do
      lists = SubscriberList.with_at_least_one_tag_of_each_type(tags: {
        topics: ["oil-and-gas/licensing"],
        another_tag_thats_not_part_of_the_subscription: ["elephants"],
      })
      expect(lists).to eq([@list2])
    end

    it "finds lists where all the tag types in the subscription have a value present, even when they have other values which aren't present " do
      lists = SubscriberList.with_at_least_one_tag_of_each_type(tags: {
        topics: ["oil-and-gas/licensing", "elephants"],
      })
      expect(lists).to eq([@list2])
    end

    it "doesn't return lists which have no tag types present in the document" do
      lists = SubscriberList.with_at_least_one_tag_of_each_type(tags: {
        another_tag_thats_not_part_of_any_subscription: ["elephants"],
      })
      expect(lists).to eq([])
    end
  end

  describe ".where_tags_equal(tag_hash)" do
    before do
      @list = create(:subscriber_list, tags: {
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency", "hm-revenue-customs"]
      })
    end

    it "requires all tag types in the document to be present in the list" do
      found_lists = SubscriberList.where_tags_equal({
        topics: ["oil-and-gas/licensing"],
      })
      expect(found_lists).to eq([])
    end

    it "requires all tag types in the list to be present in the document" do
      found_lists = SubscriberList.where_tags_equal({
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency", "hm-revenue-customs"],
        other_tag_type: ["foo"],
      })
      expect(found_lists).to eq([])
    end

  end

  describe "#tags" do
    it "deserializes the tag arrays" do
      list = create(:subscriber_list, tags: {
        topics: ["environmental-management/boating"],
      })

      list.reload

      expect(list.tags).to eq(topics: ["environmental-management/boating"])
    end
  end

  describe "#subscription_url" do
    it "provides the subscription URL based on the gov_delivery_id" do
      list = SubscriberList.new(gov_delivery_id: "UKGOVUK_4567")

      expect(list.subscription_url).to eq(
        "http://govdelivery-public.example.com/accounts/UKGOVUK/subscriber/new?topic_id=UKGOVUK_4567"
      )
    end
  end
end

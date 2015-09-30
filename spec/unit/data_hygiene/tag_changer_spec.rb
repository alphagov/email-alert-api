require "rails_helper"

RSpec.describe DataHygiene::TagChanger, "#update_records_tags" do

  it "creates a new record with an updated topic tag" do
    subscriber_list = create(:subscriber_list, tags: {
      topics: ["environmental-management/boating"],
    })
    tag_changer = DataHygiene::TagChanger.new(
      from_topic_tag: "environmental-management/boating",
      to_topic_tag: "environmental-management/speed-boating"
    )
    stub_logging(tag_changer)
    expect { tag_changer.update_records_tags }.to change(SubscriberList, :count).by(1)
    expect(tag_changer.logs).to eq [
      "Duplicating SubscriberList id: #{SubscriberList.first.id} replacing environmental-management/boating with environmental-management/speed-boating"
    ]
    expect(SubscriberList.last.gov_delivery_id).to eq subscriber_list.gov_delivery_id
    expect(SubscriberList.last.tags[:topics]).to eq ["environmental-management/speed-boating"]
  end

  it "does not create a new record for an empty to_topic_tag" do
    tag_changer = DataHygiene::TagChanger.new(
      from_topic_tag: "environmental-management/boating",
      to_topic_tag: ""
    )

    expect { tag_changer.update_records_tags }.not_to change(SubscriberList, :count)
  end

  it "preserves additional tags" do
    subscriber_list = create(:subscriber_list, tags: {
      topics: ["environmental-management/agency"],
      organisations: ["Environment Agency"]
    })
    tag_changer = DataHygiene::TagChanger.new(
      from_topic_tag: "environmental-management/agency",
      to_topic_tag: "environmental-management/speed-boating"
    )
    stub_logging(tag_changer)

    expect { tag_changer.update_records_tags }.to change(SubscriberList, :count).by(1)
    expect(tag_changer.logs).to eq [
      "Duplicating SubscriberList id: #{SubscriberList.first.id} replacing environmental-management/agency with environmental-management/speed-boating"
    ]
    expect(SubscriberList.last.gov_delivery_id).to eq subscriber_list.gov_delivery_id
    expect(SubscriberList.last.tags[:topics]).to eq ["environmental-management/speed-boating"]
    expect(SubscriberList.last.tags[:organisations]).to eq subscriber_list.tags[:organisations]
  end

  it "preserves additional topics" do
    subscriber_list = create(:subscriber_list, tags: {
      topics: ["environmental-management/agency", "environmental-management/littering"],
      organisations: ["Environment Agency"]
    })
    subscriber_list2 = create(:subscriber_list, tags: {
      topics: ["environmental-management/123agency"],
      organisations: ["Environment Agency"]
    })
    tag_changer = DataHygiene::TagChanger.new(
      from_topic_tag: "environmental-management/agency",
      to_topic_tag: "environmental-management/sewage"
    )
    stub_logging(tag_changer)

    expect { tag_changer.update_records_tags }.to change(SubscriberList, :count).by(1)
    expect(tag_changer.logs).to eq [
      "Duplicating SubscriberList id: #{SubscriberList.first.id} replacing environmental-management/agency with environmental-management/sewage"
    ]
    expect(SubscriberList.last.gov_delivery_id).to eq subscriber_list.gov_delivery_id
    expect(SubscriberList.last.tags[:topics]).to eq ["environmental-management/sewage", "environmental-management/littering"]
    expect(SubscriberList.last.tags[:organisations]).to eq subscriber_list.tags[:organisations]
  end

  # Replace the `log` method on a TopicTagger with one that appends the logged
  # messages to an array.  Return the array.
  def stub_logging(tag_changer)
    def tag_changer.log(message)
      @logs ||= []
      @logs << message
    end
    def tag_changer.logs
      @logs
    end
  end
end

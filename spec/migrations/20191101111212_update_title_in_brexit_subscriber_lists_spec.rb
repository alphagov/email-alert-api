require File.join(Rails.root, "db", "migrate", "20191101111212_update_title_in_brexit_subscriber_lists")

RSpec.describe UpdateTitleInBrexitSubscriberLists do
  it "renames the title" do
    list = FactoryBot.create(:subscriber_list, tags: { "brexit_checklist_criteria" => {} }, title: UpdateTitleInBrexitSubscriberLists::OLD_TITLE)
    expect {
      UpdateTitleInBrexitSubscriberLists.new.up
    }.to change {
      SubscriberList.find(list.id).title
    }.from(UpdateTitleInBrexitSubscriberLists::OLD_TITLE).to(UpdateTitleInBrexitSubscriberLists::NEW_TITLE)
  end

  it "does not rename the title because the tags are not brexit related" do
    list = FactoryBot.create(:subscriber_list, tags: { "alert_type" => {} }, title: UpdateTitleInBrexitSubscriberLists::OLD_TITLE)
    expect {
      UpdateTitleInBrexitSubscriberLists.new.up
    }.to_not(change {
      SubscriberList.find(list.id).title
    })
  end

  it "raises an exception because the title is unexpected" do
    FactoryBot.create(:subscriber_list, tags: { "brexit_checklist_criteria" => {} }, title: "something else")
    expect {
      UpdateTitleInBrexitSubscriberLists.new.up
    }.to raise_error("Some Brexit related lists have unexpected titles")
  end

  it "down reverts up" do
    list = FactoryBot.create(:subscriber_list, tags: { "brexit_checklist_criteria" => {} }, title: UpdateTitleInBrexitSubscriberLists::OLD_TITLE)
    expect {
      UpdateTitleInBrexitSubscriberLists.new.up
      UpdateTitleInBrexitSubscriberLists.new.down
    }.to_not(change {
      SubscriberList.find(list.id).title
    })
  end
end

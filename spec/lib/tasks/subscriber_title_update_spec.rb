RSpec.describe "subscriber_title_update" do
  describe "replace_occupied_palestinian_titles" do
    before do
      Rake::Task["subscriber_title_update:replace_occupied_palestinian_titles"].reenable
    end

    it "outputs csv rows and prints count as 2 for replaced subscriber records" do
      list1 = create(:subscriber_list, title: "Travelling to The Occupied Palestinian Territories")
      list2 = create(:subscriber_list, title: "Occupied Palestinian Territories - Area")
      list3 = create(:subscriber_list, title: "Test title")

      expect {
        Rake::Task["subscriber_title_update:replace_occupied_palestinian_titles"].invoke
      }.to output(/id,new_title.*Palestine.*Updated 2 SubscriberList titles with Palestine\./m).to_stdout

      expect(list1.reload.title).to eq("Travelling to Palestine")
      expect(list2.reload.title).to eq("Palestine - Area")
      expect(list3.reload.title).to eq("Test title")
    end

    it "prints 0 when there are no matching records" do
      create(:subscriber_list, title: "test title")

      expect {
        Rake::Task["subscriber_title_update:replace_occupied_palestinian_titles"].invoke
      }.to output(/id,new_title.*Updated 0 SubscriberList titles with Palestine\./m).to_stdout
    end
  end
end

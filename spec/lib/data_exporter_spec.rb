RSpec.describe DataExporter do
  describe "#export_csv_from_ids_at" do
    let(:date) { "2018-02-01" }
    let(:subscriber_list) { create(:subscriber_list, id: 1, title: "title") }

    before do
      # not within time period
      Timecop.freeze("2018-03-01") do
        create(:subscription, subscriber_list: subscriber_list)
        create(:subscription, :ended, subscriber_list: subscriber_list)
      end

      # within time period but only one is active
      Timecop.freeze("2018-01-01") do
        create(:subscription, subscriber_list: subscriber_list)
        create(:subscription, :ended, subscriber_list: subscriber_list)
      end

      # resubscribed within the time period, only one is active
      same_subscriber = create(:subscriber)
      create(
        :subscription, :ended, subscriber: same_subscriber, subscriber_list: subscriber_list,
        created_at: "2018-01-04", ended_at: "2018-01-05", updated_at: "2018-01-05",
      )
      create(
        :subscription, subscriber: same_subscriber, subscriber_list: subscriber_list,
        created_at: "2018-01-06", updated_at: "2018-01-06",
      )
    end

    subject { DataExporter.new.export_csv_from_ids_at(date, [subscriber_list.id]) }

    it "returns the correct number of subscriptions" do
      expect { subject }.to output("id,title,count\n1,title,2\n").to_stdout
    end
  end
end

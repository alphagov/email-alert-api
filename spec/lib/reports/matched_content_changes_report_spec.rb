RSpec.describe Reports::MatchedContentChangesReport do
  describe "#call" do
    it "outputs a CSV of matched content changes" do
      subscriber_list = create :subscriber_list_with_subscribers
      match = create :matched_content_change, subscriber_list: subscriber_list
      expect(described_class.new.call).to eq report_for([{ match: match, count: 5 }])
    end

    it "only reports on immediate subscriptions" do
      subscriber_list = create :subscriber_list
      subscriber_list.subscriptions << create(:subscription, frequency: :daily)
      create :matched_content_change, subscriber_list: subscriber_list
      expect(described_class.new.call).to eq report_for([])
    end

    it "orders the output by subscription count" do
      subscriber_list1 = create :subscriber_list_with_subscribers
      subscriber_list2 = create :subscriber_list
      subscriber_list2.subscriptions << create(:subscription)
      match1 = create :matched_content_change, subscriber_list: subscriber_list1
      match2 = create :matched_content_change, subscriber_list: subscriber_list2

      expect(described_class.new.call).to eq report_for([
        { match: match1, count: 5 }, { match: match2, count: 1 }
      ])
    end

    it "ignores lists that had no subscriptions" do
      subscriber_list = create :subscriber_list
      subscriber_list.subscriptions << create(:subscription, ended_at: 1.day.ago)
      create :matched_content_change, subscriber_list: subscriber_list
      expect(described_class.new.call).to eq report_for([])
    end

    it "includes subscriptions that ended later" do
      subscriber_list = create :subscriber_list
      subscriber_list.subscriptions << create(:subscription, ended_at: 1.day.from_now)
      match = create :matched_content_change, subscriber_list: subscriber_list
      expect(described_class.new.call).to eq report_for([{ match: match, count: 1 }])
    end

    it "allows specifying the date range to report" do
      subscriber_list = create :subscriber_list_with_subscribers
      create :matched_content_change, subscriber_list: subscriber_list
      output = described_class.new.call(start_time: 1.day.from_now.to_s, end_time: 2.days.from_now.to_s)
      expect(output).to eq report_for([])
    end

    def report_for(rows)
      headers = described_class::OUTPUT_ATTRIBUTES.keys.join(",")

      rows = [headers] + rows.map do |row|
        "#{row[:match].content_change.created_at}," \
          "government/base_path,change note,document type,publishing app,normal," \
          "#{row[:match].subscriber_list.title},#{row[:count]}"
      end

      rows.join("\n") + "\n"
    end
  end
end

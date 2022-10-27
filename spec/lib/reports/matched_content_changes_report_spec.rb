RSpec.describe Reports::MatchedContentChangesReport do
  describe "#call" do
    it "outputs a CSV of matched content changes" do
      subscriber_list = create :subscriber_list
      match = create :matched_content_change, subscriber_list: subscriber_list
      expect(described_class.new.call).to eq report_for([{ match: }])
    end

    it "allows specifying the date range to report" do
      subscriber_list = create :subscriber_list
      create :matched_content_change, subscriber_list: subscriber_list
      output = described_class.new.call(start_time: 1.day.from_now.to_s, end_time: 2.days.from_now.to_s)
      expect(output).to eq report_for([])
    end

    def report_for(rows)
      headers = described_class::OUTPUT_ATTRIBUTES.keys.join(",")

      rows = [headers] + rows.map do |row|
        "#{row[:match].content_change.created_at}," \
          "government/base_path,change note,document type,publishing app,normal," \
          "#{row[:match].subscriber_list.title}," \
          "#{row[:match].subscriber_list.slug}" \
      end

      "#{rows.join("\n")}\n"
    end
  end
end

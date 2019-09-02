RSpec.describe Reports::ContentChangesInformation do
  context "successful report" do
    before do
      @content_change = create(:content_change, processed_at: Time.now)
      @subscription_one, @subscription_two = (1..2).map { create(:subscription) }
      email_one, email_two = (1..2).map { create(:email, status: 'sent') }

      create(:subscription_content, content_change: @content_change,
             email: email_one, subscription: @subscription_one)
      create(:subscription_content, content_change: @content_change,
             email: email_two, subscription: @subscription_two)

      @start_date = Time.zone.parse(DateTime.now.beginning_of_day.to_s)
      @end_date =  Time.zone.parse(DateTime.now.end_of_day.to_s)
      @file_path = "#{Rails.root}/tmp/content_changes_time_#{@start_date}_to_#{@end_date}.csv".delete(' ')
    end

    it "generates CSV containing information around content changes for the given timeframe" do
      described_class.new(@start_date, @end_date).report
      expect(CSV.read(@file_path)[1]).to eq(
        [
          @content_change.id.to_s,
          @content_change.base_path.to_s,
          @content_change.created_at.to_s,
          "2",
          "#{@subscription_one.subscriber_list.title}, #{@subscription_two.subscriber_list.title}"
        ]
      )
    end
  end

  it "raises an error if the time passed in is not in date/time format" do
    expect { described_class.new("foobartime", "barfootime").call }
           .to raise_error(ArgumentError, 'Date(s) entered need to be of date/time format')
  end
end

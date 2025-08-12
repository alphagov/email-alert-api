RSpec.describe Reports::SubscriberCountListReport do
  let(:url) { "/url" }
  let(:created_at) { 1.month.ago.beginning_of_month }
  let(:list) { create(:subscriber_list, created_at:, title: "list 1", slug: "list-1", url:) }

  before { create_range_of_subscribers(list, created_at) }

  context "when passed a URL matching subscriber list along with start and end dates" do
    let(:start_date) { 1.month.ago.beginning_of_month }
    let(:end_date) { Time.zone.now.end_of_month }

    it "returns a list of subscribers count, excluding ended subscriptions" do
      result = described_class.new(url, start_date, end_date).call
      expect(result).to include("Date,Count")
      expect(result).to include("#{1.month.ago.beginning_of_month.strftime('%d-%m-%Y')},1")
      expect(result).to include("#{Time.zone.now.beginning_of_month.strftime('%d-%m-%Y')},4")
    end
  end

  context "when passed an invalid URL" do
    before do
      allow(SubscriberList).to receive(:find_by_url).with(url).and_return(nil)
    end

    it "gives a error message" do
      result = described_class.new(url).call
      expect(result).to include("Subscriber list cannot be found with URL")
    end
  end

  context "when passed invalid dates" do
    let(:start_date) { "invalid-start-date" }
    let(:end_date) { "invalid-end-date" }

    it "returns an error message" do
      result = described_class.new(url, start_date, end_date).call
      expect(result).to include("Cannot parse dates, are these valid ISO8601 dates?: start_date=#{start_date}, end_date=#{end_date}")
    end
  end

  context "when dates are not given" do
    it "handles TimeWithZone objects without parsing" do
      result = described_class.new(url).call
      expect(result).to include("Date,Count")
    end
  end

  context "when passed valid date strings" do
    let(:start_date) { "2025-07-01" }
    let(:end_date) { "2025-08-10" }

    it "parses string dates correctly" do
      result = described_class.new(url, start_date, end_date).call
      expect(result).to include("Date,Count")
    end
  end

  def create_range_of_subscribers(list, created_at)
    create(:subscription, subscriber_list: list, created_at:)
    create(:subscription, subscriber_list: list, created_at: Time.zone.now.beginning_of_month)
    create(:subscription, subscriber_list: list, created_at: Time.zone.now.beginning_of_month)
    create(:subscription, subscriber_list: list, created_at: Time.zone.now.beginning_of_month)
  end
end

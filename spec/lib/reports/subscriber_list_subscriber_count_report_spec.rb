RSpec.describe Reports::SubscriberListSubscriberCountReport do
  let(:url) { "/url" }
  let(:created_at) { 10.days.ago.midday }
  let(:list) { create(:subscriber_list, created_at:, title: "list 1", slug: "list-1", url:) }

  before { create_range_of_subscribers(list, created_at) }

  context "when passed a URL that matches a subscriber list" do
    let(:active_on_date) { Time.zone.now.end_of_day }

    it "returns a count up to Time.zone.now if not provided a date, excluding ended subscriptions" do
      expect(described_class.new(url).call).to include("Subscriber list for #{url} had 4 subscribers on #{active_on_date}.")
    end

    it "returns a count up to Time.zone.now if you provide a date as nil, excluding ended subscriptions" do
      expect(described_class.new(url, nil).call).to include("Subscriber list for #{url} had 4 subscribers on #{active_on_date}.")
    end

    it "returns a count up to an active_on_date, excluding ended subscriptions" do
      expect(described_class.new(url, active_on_date.advance(days: -1)).call).to eq("Subscriber list for #{url} had 3 subscribers on #{active_on_date.advance(days: -1)}.")
    end
  end

  context "when passed a URL that does not match a subscriber list" do
    it "it returns a useful message" do
      expect(described_class.new("/nope").call).to eq("Subscriber list cannot be found with URL: /nope")
    end
  end

  context "when passed a badly formatted date" do
    it "it returns a useful message" do
      expect(described_class.new(url, "20th of furberry").call).to eq("Cannot parse active_on_date, is this a valid ISO8601 date?: 20th of furberry")
    end
  end

  def create_range_of_subscribers(list, created_at)
    create(:subscription, :immediately, subscriber_list: list, created_at:)
    create(:subscription, :daily, subscriber_list: list, created_at:)
    create(:subscription, :weekly, subscriber_list: list, created_at:)
    create(:subscription, :ended, ended_at: created_at, subscriber_list: list)
    create(:subscription, :ended, ended_at: created_at, ended_reason: :frequency_changed, subscriber_list: list)
    create(:subscription, :immediately, subscriber_list: list, created_at: Time.zone.now)
  end
end

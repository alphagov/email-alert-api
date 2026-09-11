RSpec.describe Reports::SubscriberListBySlugSubscriberCountReport do
  let(:slug) { "ministry-of-magic" }
  let(:created_at) { 10.days.ago.midday }
  let(:list) { create(:subscriber_list, created_at:, title: "Ministry of Magic", slug: "ministry-of-magic", url: "/government/organisations/ministry-of-magic") }

  before { create_range_of_subscribers(list, created_at) }

  context "when passed a slug that matches a subscriber list" do
    let(:active_on_date) { Time.zone.now.end_of_day }

    it "returns a count up to Time.zone.now, excluding ended subscriptions" do
      expect(described_class.new(slug).call).to include("Subscriber list for #{slug} had 4 subscribers on #{active_on_date}.")
    end
  end

  context "when passed a slug that does not match a subscriber list" do
    it "it returns a useful message" do
      expect { described_class.new("non-existent-slug").call }
      .to raise_error(RuntimeError, "Subscriber list cannot be found with slug: non-existent-slug")
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

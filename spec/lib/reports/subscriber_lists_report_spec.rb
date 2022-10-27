RSpec.describe Reports::SubscriberListsReport do
  let(:created_at) { 10.days.ago.midday }

  before do
    list = create(:subscriber_list, created_at:, title: "list 1", slug: "list-1", url: "/url")

    create(:subscription, :immediately, subscriber_list: list, created_at:)
    create(:subscription, :daily, subscriber_list: list, created_at:)
    create(:subscription, :weekly, subscriber_list: list, created_at:)
    create(:subscription, :ended, ended_at: created_at, subscriber_list: list)
    create(:subscription, :ended, ended_at: created_at, ended_reason: :frequency_changed, subscriber_list: list)

    create(:matched_content_change, subscriber_list: list, created_at:)
    create(:matched_message, subscriber_list: list, created_at:)
  end

  it "returns data around active lists for the given date" do
    expected_criteria_bits = '{"document_type":"","tags":{"topics":{"any":["motoring/road_rage"]}},' \
      '"links":{},"email_document_supertype":"","government_document_supertype":""}'

    expected = CSV.generate do |csv|
      csv << %w[
        title
        slug
        url
        matching_criteria
        created_at
        individual_subscribers
        daily_subscribers
        weekly_subscribers
        unsubscriptions
        matched_content_changes_for_date
        matched_messages_for_date
        total_subscribers
      ]
      csv << ["list 1", "list-1", "/url", expected_criteria_bits, created_at, 1, 1, 1, 1, 1, 1, 3]
    end

    expect(described_class.new(created_at.to_s).call).to eq expected
  end

  it "returns specified headers only" do
    specified_headers = "title,individual_subscribers,daily_subscribers,weekly_subscribers,total_subscribers"
    expected = CSV.generate do |csv|
      csv << %w[
        title
        individual_subscribers
        daily_subscribers
        weekly_subscribers
        total_subscribers
      ]
      csv << ["list 1", 1, 1, 1, 3]
    end

    expect(described_class.new(created_at.to_s, headers: specified_headers).call).to eq expected
  end

  it "can filter based on comma separated list slugs" do
    create(:subscriber_list, slug: "other-list")

    output = described_class.new(created_at.to_s, slugs: "list-1,other-list").call
    expect(output.lines.count).to eq 3

    output = described_class.new(created_at.to_s, slugs: "list-1").call
    expect(output.lines.count).to eq 2
  end

  it "can filter based on list tags (as a string)" do
    create(:subscriber_list, tags: {})

    output = described_class.new(created_at.to_s, tags_pattern: "road").call
    expect(output.lines.count).to eq 2

    output = described_class.new(created_at.to_s, tags_pattern: "nothing").call
    expect(output.lines.count).to eq 1
  end

  it "can filter based on list links (as a string)" do
    create(:subscriber_list, :travel_advice)

    output = described_class.new(created_at.to_s, links_pattern: "countries").call
    expect(output.lines.count).to eq 2

    output = described_class.new(created_at.to_s, links_pattern: "nothing").call
    expect(output.lines.count).to eq 1
  end

  it "raises an error if a specified slug is not found" do
    expect { described_class.new(created_at.to_s, slugs: "other-list,list").call }
      .to raise_error("Lists not found for slugs: other-list,list")
  end

  it "raises an error if the date isn't in the past" do
    expect { described_class.new(Time.zone.today.to_s).call }
      .to raise_error("Date must be in the past")
  end

  it "raises an error if the date isn't within a year old" do
    expect { described_class.new("2019-05-01").call }
      .to raise_error("Date must be within a year old")
  end

  it "raises an error if a specified header doesn't exist" do
    expect { described_class.new(created_at.to_s, headers: "title,non-existent-header").call }
      .to raise_error("Header is not a valid option: non-existent-header")
  end
end

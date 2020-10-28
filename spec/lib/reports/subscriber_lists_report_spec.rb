RSpec.describe Reports::SubscriberListsReport do
  before do
    created_at = Time.zone.parse("2020-06-15").midday
    list = create(:subscriber_list, created_at: created_at, title: "list 1", slug: "list-1")

    create(:subscription, :immediately, subscriber_list: list, created_at: created_at)
    create(:subscription, :daily, subscriber_list: list, created_at: created_at)
    create(:subscription, :weekly, subscriber_list: list, created_at: created_at)
    create(:subscription, :ended, ended_at: created_at, subscriber_list: list, created_at: created_at)

    create(:matched_content_change, subscriber_list: list, created_at: created_at)
    create(:matched_message, subscriber_list: list, created_at: created_at)
  end

  it "returns data around active lists for the given date" do
    csv = <<~CSV
      #{Reports::SubscriberListsReport::CSV_HEADERS.join(',')}
      list 1,list-1,"{""document_type"":"""",""tags"":{""topics"":{""any"":[""motoring/road_rage""]}},""links"":{},""email_document_supertype"":"""",""government_document_supertype"":""""}",2020-06-15 12:00:00 +0100,1,1,1,1,1,1
    CSV

    expect { described_class.new("2020-06-15").call }.to output(csv).to_stdout
  end

  it "returns empty csv if there are no active subscriber lists for the given date" do
    empty_csv = <<~CSV
      #{Reports::SubscriberListsReport::CSV_HEADERS.join(',')}
    CSV

    expect { described_class.new("2020-05-01").call }.to output(empty_csv).to_stdout
  end

  it "raises an error if the date is invalid" do
    expect { described_class.new("blahhh").call }
      .to raise_error("Invalid date")
  end

  it "raises an error if the date isn't in the past" do
    expect { described_class.new(Time.zone.today.to_s).call }
      .to raise_error("Date must be in the past")
  end

  it "raises an error if the date isn't within a year old" do
    expect { described_class.new("2019-05-01").call }
      .to raise_error("Date must be within a year old")
  end
end

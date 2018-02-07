RSpec.describe ImportGovdeliveryCsv do
  let!(:first_subscribable) do
    create(:subscriber_list, gov_delivery_id: "UKGOVUK_111", title: "First")
  end

  let!(:second_subscribable) do
    create(:subscriber_list, gov_delivery_id: "UKGOVUK_222", title: "Second")
  end

  it "creates subscribers and subscriptions" do
    expect { described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv") }
      .to change(Subscriber, :count).by(2)
      .and change(Subscription, :count).by(3)
  end

  it "sets the subscriber address from the csv" do
    described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(Subscriber.first.address).to eq("foo@example.com")
    expect(Subscriber.second.address).to eq("bar@example.com")
  end

  it "associates the subscriptions with the subscribers" do
    described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(Subscription.first.subscriber.address).to eq("foo@example.com")
    expect(Subscription.second.subscriber.address).to eq("bar@example.com")
    expect(Subscription.third.subscriber.address).to eq("foo@example.com")
  end

  it "associates the subscriptions with the subscribables" do
    described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(Subscription.first.subscriber_list.title).to eq("First")
    expect(Subscription.second.subscriber_list.title).to eq("First")
    expect(Subscription.third.subscriber_list.title).to eq("Second")
  end

  it "sets the frequencies on the subscriptions" do
    described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(Subscription.first.frequency).to eq(Frequency::IMMEDIATELY)
    expect(Subscription.second.frequency).to eq(Frequency::DAILY)
    expect(Subscription.third.frequency).to eq(Frequency::IMMEDIATELY)
  end

  it "is idempotent" do
    described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect { described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv") }
      .to change(Subscriber, :count).by(0)
      .and change(Subscription, :count).by(0)
  end

  it "returns a report of imported rows" do
    report = described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(report).to eq(
      success_count: 3,
      failed_count: 0,
      failed_rows: [],
    )
  end

  context "when the subscribable name doesn't match the csv" do
    before { second_subscribable.update!(title: "Something else") }

    it "does not import a subscription for that subscribable" do
      expect { described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv") }
        .to change(Subscription, :count).by(2)
    end

    it "includes the failed rows in the report" do
      report = described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

      expect(report).to eq(
        success_count: 2,
        failed_count: 1,
        failed_rows: [
          [
            "Name mismatch: Second != Something else",
            {
              "TOPIC_ID" => "67890",
              "TOPIC_NAME" => "Second",
              "TOPIC_CODE" => "UKGOVUK_222",
              "TOPIC_VISIBILITY" => "1",
              "SUBSCRIBER_ID" => "1111111111",
              "DESTINATION" => "foo@example.com"
            },
          ],
        ]
      )
    end
  end

  context "when an io object is provided" do
    let(:io) { StringIO.new }

    before { second_subscribable.update!(title: "Something else") }

    it "logs output to the io object" do
      described_class.import("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv", output_io: io)
      expect(io.string).to eq("..F")
    end
  end

  context "when the file has the wrong encoding" do
    it "raises an error" do
      expect { described_class.import("spec/lib/csv_fixture_broken.csv", "spec/lib/csv_digest_fixture.csv") }
        .to raise_error(/should be WINDOWS-1252/)
    end
  end
end

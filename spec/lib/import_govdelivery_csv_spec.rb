RSpec.describe ImportGovdeliveryCsv do
  before do
    allow($stdin).to receive(:gets).and_return("<enter>")
    allow($stdout).to receive(:write)
  end

  let!(:first_subscribable) do
    create(:subscriber_list, gov_delivery_id: "UKGOVUK_111", title: "First")
  end

  let!(:second_subscribable) do
    create(:subscriber_list, gov_delivery_id: "UKGOVUK_222", title: "Second")
  end

  it "creates subscribers and subscriptions" do
    expect { described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv") }
      .to change(Subscriber, :count).by(2)
      .and change(Subscription, :count).by(3)
  end

  it "sets the subscriber address from the csv" do
    described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(Subscriber.first.address).to eq("foo@example.com")
    expect(Subscriber.second.address).to eq("bar@example.com")
  end

  it "associates the subscriptions with the subscribers" do
    described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(Subscription.first.subscriber.address).to eq("foo@example.com")
    expect(Subscription.second.subscriber.address).to eq("bar@example.com")
    expect(Subscription.third.subscriber.address).to eq("foo@example.com")
  end

  it "associates the subscriptions with the subscribables" do
    described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(Subscription.first.subscriber_list.title).to eq("First")
    expect(Subscription.second.subscriber_list.title).to eq("First")
    expect(Subscription.third.subscriber_list.title).to eq("Second")
  end

  it "sets the frequencies on the subscriptions" do
    described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(Subscription.first.frequency).to eq(Frequency::IMMEDIATELY)
    expect(Subscription.second.frequency).to eq(Frequency::DAILY)
    expect(Subscription.third.frequency).to eq(Frequency::IMMEDIATELY)
  end

  it "is idempotent" do
    described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect { described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv") }
      .to change(Subscriber, :count).by(0)
      .and change(Subscription, :count).by(0)
  end

  context "when the file has the wrong encoding" do
    it "raises an error" do
      expect { described_class.call("spec/lib/csv_fixture_broken.csv", "spec/lib/csv_digest_fixture.csv") }
        .to raise_error(/should be WINDOWS-1252/)
    end
  end

  context "when doing a fake import" do
    it "sets the addresses to AWS success addresses" do
      described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv", fake_import: true)

      expect(Subscription.first.subscriber.address).to eq("success+767e74eab7081c41e0b83630511139d130249666@simulator.amazonses.com")
      expect(Subscription.second.subscriber.address).to eq("success+1ac2c5ab67ab3279b2de1d2bed879b2a63e59ee7@simulator.amazonses.com")
      expect(Subscription.third.subscriber.address).to eq("success+767e74eab7081c41e0b83630511139d130249666@simulator.amazonses.com")
    end
  end
end

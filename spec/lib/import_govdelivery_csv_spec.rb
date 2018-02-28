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

  context "with the wrong csvs" do
    it "raises an error if subscription csv does not include 'topic_code'" do
      expect { described_class.call("spec/lib/csv_digest_fixture.csv", "spec/lib/csv_digest_fixture.csv") }
        .to raise_error(RuntimeError, "Your subscription csv is incorrect.")
    end

    it "raises an error if the digest csv does not include 'digest_for'" do
      expect { described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_fixture.csv") }
        .to raise_error(RuntimeError, "Your digest csv is incorrect.")
    end

    it "raises an error if the digest csv does not include 'digest_for' and the subscription csv does not include 'topic_code'" do
      expect { described_class.call("spec/lib/csv_digest_fixture.csv", "spec/lib/csv_fixture.csv") }
        .to raise_error(RuntimeError, "Your subscription csv is incorrect. Your digest csv is incorrect.")
    end
  end

  it "creates subscribers and subscriptions" do
    expect { described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv") }
      .to change(Subscriber, :count).by(2)
      .and change(Subscription, :count).by(3)
  end

  it "sets the subscriber address from the csv" do
    described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(Subscriber.pluck(:address)).to match_array(%w(foo@example.com bar@example.com))
  end

  def find_subscription(address, title)
    Subscription
      .joins(:subscriber, :subscriber_list)
      .find_by(subscribers: { address: address }, subscriber_lists: { title: title })
  end

  it "associates the subscriptions with the subscribers and subscribables" do
    described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(find_subscription("foo@example.com", "First")).to_not be_nil
    expect(find_subscription("bar@example.com", "First")).to_not be_nil
    expect(find_subscription("foo@example.com", "Second")).to_not be_nil
  end

  it "sets the frequencies on the subscriptions" do
    described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

    expect(find_subscription("foo@example.com", "First").frequency).to eq(Frequency::IMMEDIATELY)
    expect(find_subscription("bar@example.com", "First").frequency).to eq(Frequency::DAILY)
    expect(find_subscription("foo@example.com", "Second").frequency).to eq(Frequency::IMMEDIATELY)
  end

  context "when the subscriber list is travel advice" do
    let!(:first_subscribable) do
      create(:subscriber_list, :travel_advice, gov_delivery_id: "UKGOVUK_111", title: "First")
    end

    it "sets the frequency to immediate" do
      described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

      expect(find_subscription("bar@example.com", "First").frequency).to eq(Frequency::IMMEDIATELY)
    end
  end

  context "when the subscriber list is a medical safety alery" do
    let!(:first_subscribable) do
      create(:subscriber_list, :medical_safety_alert, gov_delivery_id: "UKGOVUK_111", title: "First")
    end

    it "sets the frequency to immediate" do
      described_class.call("spec/lib/csv_fixture.csv", "spec/lib/csv_digest_fixture.csv")

      expect(find_subscription("bar@example.com", "First").frequency).to eq(Frequency::IMMEDIATELY)
    end
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

      expect(find_subscription("success+767e74eab7081c41e0b83630511139d130249666@simulator.amazonses.com", "First")).to_not be_nil
      expect(find_subscription("success+1ac2c5ab67ab3279b2de1d2bed879b2a63e59ee7@simulator.amazonses.com", "First")).to_not be_nil
      expect(find_subscription("success+767e74eab7081c41e0b83630511139d130249666@simulator.amazonses.com", "Second")).to_not be_nil
    end
  end
end

RSpec.describe ContentChangeSubscriptionQuery do
  let(:content_change) do
    create(:content_change, tags: { topics: ["oil-and-gas/licensing"] })
  end

  let(:subscriber_list) do
    create(:subscriber_list, tags: { topics: ["oil-and-gas/licensing"] })
  end

  before do
    create(
      :matched_content_change,
      content_change: content_change,
      subscriber_list: subscriber_list,
    )
  end

  subject { described_class.call(content_change: content_change) }

  describe ".call" do
    context "with a subscription" do
      before do
        create(:subscription, subscriber_list: subscriber_list)
      end

      it "returns the subscriptions" do
        expect(subject.count).to eq(1)
      end
    end

    context "with two subscriptions" do
      before do
        create(:subscription, subscriber_list: subscriber_list)
        create(:subscription, subscriber_list: subscriber_list, subscriber: create(:subscriber, address: "test2@example.com"))
      end

      it "returns the subscriptions" do
        expect(subject.count).to eq(2)
      end
    end

    context "with no subscriptions" do
      before do
        create(:subscription)
      end

      it "returns no subscriptions" do
        expect(subject.count).to eq(0)
      end
    end

    context "with daily subscription" do
      before do
        create(:subscription, frequency: "daily", subscriber_list: subscriber_list)
      end

      it "does not return them" do
        expect(subject.count).to eq(0)
      end
    end

    context "with weekly subscription" do
      before do
        create(:subscription, frequency: "weekly", subscriber_list: subscriber_list)
      end

      it "does not return them" do
        expect(subject.count).to eq(0)
      end
    end
  end
end

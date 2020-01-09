RSpec.describe Clean::InvalidSubscriberLists do
  let(:subject) { described_class.new }
  context "when there are invalid lists" do
    let!(:list) { create(:subscriber_list_with_invalid_tags, :skip_validation) }

    describe "#invalid_lists" do
      it "returns all invalid subscriber lists" do
        expect(subject.invalid_lists.count).to eq(1)
        expect(subject.invalid_lists).to include(list)
      end
    end
  end

  context "when there are no invalid lists" do
    let!(:list) { create(:subscriber_list) }

    describe "#invalid_lists" do
      it "returns zero subscriber lists" do
        expect(subject.invalid_lists.count).to eq(0)
        expect(subject.invalid_lists).to_not include(list)
      end
    end
  end

  describe "#destroy_invalid_subscriber_lists" do
    let!(:invalid_list1) { create(:subscriber_list_with_invalid_tags, :skip_validation, subscriber_count: 0) }
    let!(:invalid_list2) { create(:subscriber_list_with_invalid_tags, :skip_validation, subscriber_count: 2) }
    let!(:valid_list) { create(:subscriber_list) }
    let!(:subscriber) { create(:subscriber) }
    let!(:subscription) { create(:subscription, :ended, subscriber: subscriber, subscriber_list: invalid_list1) }

    it "deletes invalid subscriber lists which don't have active subscriptions" do
      expect {
        subject.destroy_invalid_subscriber_lists(dry_run: false)
      }.to(change { SubscriberList.count }.by(-1))
    end

    it "deletes subscriptions to invalid subscriber lists" do
      expect {
        subject.destroy_invalid_subscriber_lists(dry_run: false)
      }.to(change { subscriber.subscriptions.count }.by(-1))
    end

    it "does nothing during a dry run which is the default" do
      expect {
        subject.destroy_invalid_subscriber_lists
      }.not_to(change { SubscriberList.count })
    end
  end
end

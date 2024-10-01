RSpec.describe BulkUnsubscribeListJob do
  let(:message) { nil }

  let!(:subscriber_list) { create(:subscriber_list) }

  let!(:subscriber) do
    create(:subscriber).tap do |subscriber|
      create(:subscription, subscriber:, subscriber_list:)
    end
  end

  let!(:other_subscriber) do
    create(:subscriber).tap do |subscriber|
      other_list = create(:subscriber_list)
      create(:subscription, subscriber:, subscriber_list: other_list)
    end
  end

  describe "#perform" do
    it "unsubscribes members of the subscriber list" do
      expect { described_class.new.perform(subscriber_list.id, message&.id) }.to(change { subscriber.ended_subscriptions.count })
    end

    it "does not unsubscribe users from other subscriber lists" do
      expect { described_class.new.perform(subscriber_list.id, message&.id) }.not_to(change { other_subscriber.ended_subscriptions.count })
    end

    context "when a message is given" do
      let(:message) do
        create(
          :message,
          criteria_rules: [{ id: subscriber_list.id }],
        )
      end

      it "delegates to ProcessMessageWorker" do
        doub = instance_double(ProcessMessageWorker)
        expect(doub).to receive(:perform).with(message.id)

        expect(ProcessMessageWorker).to receive(:new).and_return(doub)

        described_class.new.perform(subscriber_list.id, message.id)
      end
    end
  end
end

RSpec.describe MessageHandlerService do
  describe ".call" do
    let(:params) do
      {
        title: "Message title",
        body: "Message body",
        criteria_rules: [
          {
            type: "tag",
            key: "brexit_checker_criteria",
            value: "eu-national",
          },
        ],
      }
    end

    let(:govuk_request_id) { SecureRandom.uuid }

    it "creates a Message" do
      expect { described_class.call(params:, govuk_request_id:) }
        .to change { Message.count }.by(1)
      expect(Message.last).to have_attributes(
        title: "Message title",
        body: "Message body",
      )
    end

    it "records a metric" do
      expect(Metrics).to receive(:message_created)
      described_class.call(params:, govuk_request_id:)
    end

    it "queues a job" do
      expect(ProcessMessageWorker).to receive(:perform_async)

      described_class.call(params:, govuk_request_id:)
    end

    it "raises errors if the Message is invalid" do
      expect { described_class.call(params: {}, govuk_request_id:) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it "can store the user that created the item" do
      user = create(:user)

      described_class.call(
        params:,
        govuk_request_id:,
        user:,
      )

      expect(Message.last).to have_attributes(signon_user_uid: user.uid)
    end

    it "can use the sender_message_id as the Message id" do
      uuid = SecureRandom.uuid

      described_class.call(
        params: params.merge(sender_message_id: uuid),
        govuk_request_id:,
      )

      expect(Message.last).to have_attributes(
        id: uuid,
        sender_message_id: uuid,
      )
    end
  end
end

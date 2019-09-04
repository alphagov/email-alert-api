RSpec.describe MessageHandlerService do
  describe ".call" do
    let(:params) do
      {
        title: "Message title",
        body: "Message body",
        document_type: "document_type",
        criteria_rules: [
          {
            type: "tag",
            key: "brexit_checker_criteria",
            value: "eu-national"
          },
        ],
        tags: {
          topics: ["oil-and-gas/licensing"],
        },
        links: {},
      }
    end

    let(:govuk_request_id) { SecureRandom.uuid }

    it "creates a Message" do
      expect { described_class.call(params: params, govuk_request_id: govuk_request_id) }
        .to change { Message.count }.by(1)
      expect(Message.last).to have_attributes(
        title: "Message title",
        body: "Message body",
        document_type: "document_type",
      )
    end

    it "records a metric" do
      expect(MetricsService).to receive(:message_created)
      described_class.call(params: params, govuk_request_id: govuk_request_id)
    end

    it "queues a job" do
      expect(ProcessMessageWorker).to receive(:perform_async)

      described_class.call(params: params, govuk_request_id: govuk_request_id)
    end

    it "raises errors if the Message is invalid" do
      expect { described_class.call(params: {}, govuk_request_id: govuk_request_id) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it "can store the user that created the item" do
      user = create(:user)

      described_class.call(params: params,
                           govuk_request_id: govuk_request_id,
                           user: user)

      expect(Message.last).to have_attributes(signon_user_uid: user.uid)
    end

    it "can add content_store_document_type to links and tags" do
      document_type = "news_story"
      modified_params = params.merge(document_type: document_type)

      described_class.call(params: modified_params,
                           govuk_request_id: govuk_request_id)

      expect(Message.last).to have_attributes(
        links: a_hash_including(content_store_document_type: document_type),
        tags: a_hash_including(content_store_document_type: document_type),
      )
    end

    it "can add GOV.UK supertypes to links and tags" do
      allow(GovukDocumentTypes)
        .to receive(:supertypes)
        .and_return(navigation_document_supertype: "other")

      modified_params = params.merge(document_type: "news_story")

      described_class.call(params: modified_params,
                           govuk_request_id: govuk_request_id)

      expect(Message.last).to have_attributes(
        links: a_hash_including(navigation_document_supertype: "other"),
        tags: a_hash_including(navigation_document_supertype: "other"),
      )
    end
  end
end

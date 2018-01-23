RSpec.describe NotificationHandlerService do
  before do
    Timecop.freeze(Time.local(2017, 1, 1, 9))
    Sidekiq::Testing.fake!
  end

  after do
    Timecop.return
  end

  let(:params) {
    {
      subject: "This is a subject",
      body: "body stuff",
      tags: {
        topics: ["oil-and-gas/licensing"]
      },
      links: {
        organisations: [
          "c380ea42-5d91-41cc-b3cd-0a4cfe439461"
        ]
      },
      content_id: "afe78383-6b27-45a4-92ae-a579e416373a",
      title: "Travel advice",
      change_note: "This is a change note",
      description: "This is a description",
      base_path: "/government/things",
      public_updated_at: Time.now.to_s,
      email_document_supertype: "email document supertype",
      government_document_supertype: "government document supertype",
      document_type: "document type",
      publishing_app: "publishing app",
      govuk_request_id: "request-id",
    }
  }

  let!(:subscriber_list) do
    create(:subscriber_list, tags: { topics: ["oil-and-gas/licensing"] })
  end

  describe ".call" do
    it "creates a ContentChange" do
      expect { described_class.call(params: params) }
        .to change { ContentChange.count }.by(1)
    end

    it "creates a MatchedContentChange" do
      expect { described_class.call(params: params) }
        .to change { MatchedContentChange.count }.by(1)
    end

    let(:content_change) { create(:content_change) }

    it "enqueues the content change to be processed by the subscription content worker" do
      allow(ContentChange).to receive(:create!).and_return(content_change)

      expect(SubscriptionContentWorker)
        .to receive(:perform_async)
        .with(content_change.id)

      described_class.call(params: params)
    end

    it "reports ContentChange errors to Sentry and swallows them" do
      allow(ContentChange).to receive(:create!).and_raise(
        ActiveRecord::RecordInvalid
      )
      expect(Raven).to receive(:capture_exception).with(
        instance_of(ActiveRecord::RecordInvalid),
        tags: { version: 2 }
      )

      expect { described_class.call(params: params) }
        .not_to raise_error
    end
  end
end

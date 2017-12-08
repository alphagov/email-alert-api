require 'rails_helper'

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

  let(:subscriber_list) do
    create(:subscriber_list, tags: { topics: ["oil-and-gas/licensing"] })
  end

  describe ".call" do
    it "creates a ContentChange" do
      notification_params = {
        content_id: params[:content_id],
        title: params[:title],
        change_note: params[:change_note],
        description: params[:description],
        base_path: params[:base_path],
        links: params[:links],
        tags: params[:tags],
        public_updated_at: DateTime.parse(params[:public_updated_at]),
        email_document_supertype: params[:email_document_supertype],
        government_document_supertype: params[:government_document_supertype],
        govuk_request_id: params[:govuk_request_id],
        document_type: params[:document_type],
        publishing_app: params[:publishing_app],
      }

      expect(ContentChange).to receive(:create!)
        .with(notification_params)
        .and_return(double(id: 1, **notification_params))

      described_class.call(params: params)
    end

    it "enqueues the content change to be processed by the subscription content worker" do
      allow(ContentChange).to receive(:create!).and_return(double(id: 1))
      expect(SubscriptionContentWorker)
        .to receive(:perform_async)
        .with(1, :low)

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

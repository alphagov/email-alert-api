require 'rails_helper'

RSpec.describe NotificationHandler do
  before do
    Timecop.freeze(Time.local(2017, 1, 1, 9))
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
    it "calls create on ContentChange" do
      notification_params = {
        content_id: params[:content_id],
        title: params[:title],
        change_note: params[:change_note],
        description: params[:description],
        base_path: params[:base_path],
        links: params[:links],
        tags: params[:tags],
        public_updated_at: params[:public_updated_at],
        email_document_supertype: params[:email_document_supertype],
        government_document_supertype: params[:government_document_supertype],
        govuk_request_id: params[:govuk_request_id],
        document_type: params[:document_type],
        publishing_app: params[:publishing_app],
      }

      expect(ContentChange).to receive(:create!)
        .with(notification_params)
        .and_return(double(id: 1, **notification_params))

      allow(Email).to receive(:create_from_params!)

      NotificationHandler.call(params: params)
    end

    context "with a courtesy subscription" do
      let!(:subscriber) { create(:subscriber, address: "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk") }

      it "calls create on Email" do
        content_change = create(:content_change)
        allow(ContentChange).to receive(:create!).and_return(
          content_change
        )

        expect(Email).to receive(:create_from_params!).with(
          title: "Travel advice",
          change_note: "This is a change note",
          description: "This is a description",
          base_path: "/government/things",
          public_updated_at: DateTime.parse("2017/01/01 09:00"),
          address: "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk",
        )

        NotificationHandler.call(params: params)
      end

      it "sends the email to the subscriber" do
        expect(DeliverEmailWorker).to receive(:perform_async_with_priority).with(
          kind_of(Integer), priority: :low,
        )

        NotificationHandler.call(params: params)
      end
    end

    context "with a subscription" do
      let(:subscriber) { create(:subscriber) }

      before do
        create(:subscription, subscriber_list: subscriber_list, subscriber: subscriber)
      end

      it "sends the email to all subscribers" do
        expect(DeliverEmailWorker).to receive(:perform_async_with_priority).with(
          kind_of(Integer), priority: :low,
        ).once

        NotificationHandler.call(params: params)
      end

      it "does not send an email to other subscribers" do
        create(:subscriber, address: "test2@test.com")

        expect(DeliverEmailWorker).to receive(:perform_async_with_priority).once

        NotificationHandler.call(params: params)
      end

      context "with a low priority" do
        before do
          params[:priority] = "low"
        end

        it "sends the email with a low priority" do
          expect(DeliverEmailWorker).to receive(:perform_async_with_priority).with(
            kind_of(Integer), priority: :low,
          )

          NotificationHandler.call(params: params)
        end
      end

      context "with a high priority" do
        before do
          params[:priority] = "high"
        end

        it "sends the email with a high priority" do
          expect(DeliverEmailWorker).to receive(:perform_async_with_priority).with(
            kind_of(Integer), priority: :high,
          )

          NotificationHandler.call(params: params)
        end
      end

      it "reports Email errors to Sentry and swallows them" do
        allow(Email).to receive(:create_from_params!).and_raise(
          ActiveRecord::RecordInvalid
        )
        expect(Raven).to receive(:capture_exception).with(
          instance_of(ActiveRecord::RecordInvalid),
          tags: { version: 2 }
        )

        expect {
          NotificationHandler.call(params: params)
        }.not_to raise_error
      end
    end

    it "reports ContentChange errors to Sentry and swallows them" do
      allow(ContentChange).to receive(:create!).and_raise(
        ActiveRecord::RecordInvalid
      )
      expect(Raven).to receive(:capture_exception).with(
        instance_of(ActiveRecord::RecordInvalid),
        tags: { version: 2 }
      )

      expect {
        NotificationHandler.call(params: params)
      }.not_to raise_error
    end
  end
end

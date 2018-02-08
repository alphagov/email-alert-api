RSpec.describe "Sending a notification", type: :request do
  context "v1" do
    context "with authentication and authorisation" do
      before do
        login_with_internal_app
        Sidekiq::Testing.fake!
        @gov_delivery = double(:gov_delivery, send_bulletin: nil)
        allow(Services).to receive(:gov_delivery).and_return(@gov_delivery)
        allow(NotificationHandlerService).to receive(:call)
      end

      after do
        Sidekiq::Worker.clear_all
      end

      it "returns a 202" do
        send_notification(topics: ["oil-and-gas/licensing"])

        expect(response.status).to eq(202)
      end

      it "kicks off a notification job" do
        expect {
          send_notification(topics: ["oil-and-gas/licensing"])
        }.to change(NotificationWorker.jobs, :count).from(0).to(1)
      end

      it "sends notifications for the right subscriber lists" do
        relevant_list_ids, _irrelevant_list_ids = create_many_lists

        send_notification(
          topics: ["oil-and-gas/licensing"],
          organisations: ["environment-agency", "hm-revenue-customs"]
        )

        NotificationWorker.drain

        expect(@gov_delivery).to have_received(:send_bulletin)
          .with(
            relevant_list_ids,
            "This is a sample subject",
            "Here is some body copy<span data-govuk-request-id=\"request-id\"></span>",
            {},
        )
      end

      it "sends notifications with options if given" do
        relevant_list_ids, _irrelevant_list_ids = create_many_lists

        send_notification({
          topics: ["oil-and-gas/licensing"],
          organisations: ["environment-agency", "hm-revenue-customs"]
        },
        from_address_id: "12345",
        urgent: true,
        header: "foo",
        footer: "bar")

        NotificationWorker.drain

        expect(@gov_delivery).to have_received(:send_bulletin)
          .with(
            relevant_list_ids,
            "This is a sample subject",
            "Here is some body copy<span data-govuk-request-id=\"request-id\"></span>",
            "from_address_id" => "12345",
            "urgent" => true,
            "header" => "foo",
            "footer" => "bar"
        )
      end

      it "doesn't send notifications if there's no lists" do
        send_notification(
          topics: ["oil-and-gas/licensing"],
          organisations: ["environment-agency", "hm-revenue-customs"]
        )

        NotificationWorker.drain

        expect(@gov_delivery).not_to have_received(:send_bulletin)
      end

      def create_many_lists
        all_match = create(
          :subscriber_list,
          tags: {
            topics: ["oil-and-gas/licensing"],
            organisations: ["environment-agency", "hm-revenue-customs"]
          }
        )

        partial_type_match = create(
          :subscriber_list,
          tags: {
            topics: ["oil-and-gas/licensing"],
            browse_pages: ["tax/vat"]
          }
        )

        full_type_partial_tag_match = create(
          :subscriber_list,
          tags: {
            topics: ["oil-and-gas/licensing"],
            organisations: ["environment-agency"]
          }
        )

        full_type_no_tag_match = create(
          :subscriber_list, tags: {
            topics: ["schools-colleges/administration-finance"],
            organisations: ["department-for-education"]
          }
        )

        full_type_but_empty = create(
          :subscriber_list, tags: {
            topics: [],
            organisations: ["environment-agency", "hm-revenue-customs"]
          }
        )

        relevant_lists = [
          all_match,
          full_type_partial_tag_match
        ]

        irrelevant_lists = [
          partial_type_match,
          full_type_no_tag_match,
          full_type_but_empty
        ]

        [
          relevant_lists.map(&:gov_delivery_id).uniq,
          irrelevant_lists.map(&:gov_delivery_id).uniq
        ]
      end

      def send_notification(tags, options = {})
        request_body = JSON.dump({
          subject: "This is a sample subject",
          body: "Here is some body copy",
          tags: tags,
        }.merge(options))

        post "/notifications", params: request_body, headers: JSON_HEADERS
      end
    end
    context "without authentication" do
      it "returns a 403" do
        post "/notifications", params: {}, headers: {}
        expect(response.status).to eq(403)
      end
    end

    context "without authorisation" do
      it "returns a 403" do
        login_with_signin
        post "/notifications", params: {}, headers: {}
        expect(response.status).to eq(403)
      end
    end
  end

  context "v2" do
    context "with authentication and authorisation" do
      let(:request_params) {
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
        }.to_json
      }

      before do
        login_with_internal_app
        allow(NotificationWorker).to receive(:perform_async)
        post "/notifications", params: request_params, headers: JSON_HEADERS
      end

      # it "creates a Notification" do
      #   expect(ContentChange.count).to eq(1)
      # end
    end

    context "without authentication" do
      it "returns 403" do
        post "/notifications", params: {}, headers: {}

        expect(response.status).to eq(403)
      end
    end

    context "without authorisation" do
      it "returns 403" do
        login_with_signin
        post "/notifications", params: {}, headers: {}

        expect(response.status).to eq(403)
      end
    end
  end
end

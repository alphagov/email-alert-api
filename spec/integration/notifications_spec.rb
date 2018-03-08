RSpec.describe "Receiving a notification", type: :request do
  context "with authentication and authorisation" do
    describe "#create" do
      let(:body) {
        <<~BODY
          <div>
            <div>Travel advice</div>
          </div>
        BODY
      }

      let(:expected_body) {
        <<~BODY
          <div>
            <div>Travel advice</div>
          </div>
          <span data-govuk-request-id="12345-67890"></span>
        BODY
      }

      let(:notification_params) {
        {
          subject: "This is a subject",
          body: body,
          tags: {
            topics: ["oil-and-gas/licensing"]
          },
          public_updated_at: "2018-02-07 10:00:00",
          base_path: "/government/test/document",
          content_id: "21b21a21-0534-46ce-bb70-c996a4edd492",
        }
      }

      let(:expected_notification_params) {
        notification_params
          .merge(links: {})
          .merge(body: expected_body.strip)
          .merge(govuk_request_id: '12345-67890')
      }

      before do
        login_with_internal_app
        allow(GdsApi::GovukHeaders).to receive(:headers)
          .and_return(govuk_request_id: "12345-67890")
      end

      it "serializes the tags and passes them to the NotificationHandlerService" do
        expect(NotificationHandlerService).to receive(:call).with(
          params: expected_notification_params,
          user: anything,
        )

        post "/notifications", params: notification_params.merge(format: :json)
      end

      it "allows an optional document_type parameter" do
        notification_params[:document_type] = "travel_advice"
        expect(NotificationHandlerService).to receive(:call).with(
          params: expected_notification_params,
          user: anything,
        )

        post "/notifications", params: notification_params.merge(format: :json)
      end

      it "allows an optional email_document_supertype parameter" do
        notification_params[:email_document_supertype] = "travel_advice"
        expect(NotificationHandlerService).to receive(:call).with(
          params: expected_notification_params,
          user: anything,
        )

        post "/notifications", params: notification_params.merge(format: :json)
      end

      it "allows an optional government_document_supertype parameter" do
        notification_params[:government_document_supertype] = "travel_advice"
        expect(NotificationHandlerService).to receive(:call).with(
          params: expected_notification_params,
          user: anything,
        )

        post "/notifications", params: notification_params.merge(format: :json)
      end

      context "when a duplicate content change exists" do
        before do
          create(
            :content_change,
            public_updated_at: "2018-02-07 10:00:00",
            base_path: "/government/test/document",
            content_id: "21b21a21-0534-46ce-bb70-c996a4edd492"
          )
        end

        it "returns a 409" do
          post "/notifications", params: notification_params.merge(format: :json)
          expect(response.status).to eq(409)
        end

        it "doesn't call NotificationHandlerService" do
          expect(NotificationHandlerService).not_to receive(:call)
          post "/notifications", params: notification_params.merge(format: :json)
        end
      end
    end
  end

  context "without authentication" do
    it "returns a 403" do
      post "/notifications", params: {}
      expect(response.status).to eq(403)
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      post "/notifications", params: {}
      expect(response.status).to eq(403)
    end
  end
end

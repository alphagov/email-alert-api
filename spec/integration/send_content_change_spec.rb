RSpec.describe "Sending a content change", type: :request do
  let(:valid_request_params) do
    {
      subject: "This is a subject",
      body: "body stuff",
      tags: {
        topics: ["oil-and-gas/licensing"]
      },
      links: {
        organisations: %w[
          c380ea42-5d91-41cc-b3cd-0a4cfe439461
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
  end

  context "with authentication and authorisation" do
    before do
      login_with_internal_app
      post "/content-changes", params: valid_request_params, headers: JSON_HEADERS
    end

    it "creates a ContentChange" do
      expect(ContentChange.count).to eq(1)
    end
  end

  context "without authentication" do
    it "returns 401" do
      without_login do
        post "/content-changes", params: {}, headers: {}
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns 403" do
      login_with_signin
      post "/content-changes", params: {}, headers: {}

      expect(response.status).to eq(403)
    end
  end

  context "with legacy endpoint" do
    it "creates a ContentChange" do
      login_with_internal_app
      expect { post "/notifications", params: valid_request_params, headers: JSON_HEADERS }
        .to change { ContentChange.count }
        .by(1)
    end
  end
end

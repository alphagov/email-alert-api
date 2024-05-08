RSpec.describe "Sending a content change", type: :request do
  let(:valid_request_params) do
    {
      subject: "This is a subject",
      body: "body stuff",
      tags: {
        tribunal_decision_categories: %w[transfer-of-undertakings],
      },
      links: {
        organisations: %w[
          c380ea42-5d91-41cc-b3cd-0a4cfe439461
        ],
      },
      content_id: "afe78383-6b27-45a4-92ae-a579e416373a",
      title: "Travel advice",
      change_note: "This is a change note",
      description: "This is a description",
      base_path: "/government/things",
      public_updated_at: Time.zone.now.to_s,
      email_document_supertype: "email document supertype",
      government_document_supertype: "government document supertype",
      document_type: "document type",
      publishing_app: "publishing app",
    }
  end

  context "with an invalid request" do
    it "returns a 422" do
      post "/content-changes",
           params: valid_request_params.merge(title: nil).to_json,
           headers: json_headers
      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)).to match(
        "error" => "Unprocessable Entity",
        "details" => { "title" => ["can't be blank"] },
      )
    end
  end

  context "with authentication and authorisation" do
    before do
      login_with_internal_app
      post "/content-changes",
           params: valid_request_params.to_json,
           headers: json_headers
    end

    it "creates a ContentChange" do
      expect(ContentChange.count).to eq(1)
    end
  end

  context "when a duplicate content change exists" do
    before do
      create(
        :content_change,
        base_path: valid_request_params[:base_path],
        content_id: valid_request_params[:content_id],
        public_updated_at: valid_request_params[:public_updated_at],
      )
    end

    it "returns a 409" do
      post "/content-changes",
           params: valid_request_params.to_json,
           headers: json_headers
      expect(response.status).to eq(409)
    end
  end

  context "without authentication" do
    it "returns 401" do
      without_login do
        post "/content-changes", params: {}.to_json, headers: {}
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns 403" do
      login_with_signin
      post "/content-changes", params: {}.to_json, headers: {}

      expect(response.status).to eq(403)
    end
  end
end

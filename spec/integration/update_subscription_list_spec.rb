RSpec.describe "Updating a subscriber list", type: :request do
  let!(:subscriber_list) { create(:subscriber_list) }
  let(:update_subscriber_lists_path) { "/subscriber-lists/#{slug}" }
  let(:slug) { subscriber_list.slug }
  let(:update_params) do
    {
      "title" => "A new title",
    }
  end

  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    it "returns a 200" do
      patch update_subscriber_lists_path, params: update_params.to_json, headers: json_headers
      expect(response.status).to eq(200)
    end

    it "returns the subscriber list with updated title" do
      patch update_subscriber_lists_path, params: update_params.to_json, headers: json_headers

      expect(JSON.parse(response.body).dig("subscriber_list", "title")).to eq(update_params["title"])
    end

    it "returns 422 if no allowed permitted parameters are provided" do
      patch update_subscriber_lists_path, params: {}, headers: json_headers
      expect(response.status).to eq(422)
    end

    it "returns 422 if a title with value of nil is provided" do
      patch update_subscriber_lists_path, params: { title: nil }.to_json, headers: json_headers
      expect(response.status).to eq(422)
    end

    context "when a description is provided" do
      let(:update_params) do
        {
          "description" => "A new list description",
        }
      end

      it "returns the subscriber list with an updated description" do
        patch update_subscriber_lists_path, params: update_params.to_json, headers: json_headers

        expect(JSON.parse(response.body).dig("subscriber_list", "description")).to eq(update_params["description"])
      end
    end

    context "when a both a title and description are provided" do
      let(:update_params) do
        {
          "title" => "A new title",
          "description" => "A new list description",
        }
      end

      it "returns the subscriber list with an updated title and description" do
        patch update_subscriber_lists_path, params: update_params.to_json, headers: json_headers

        expect(JSON.parse(response.body).dig("subscriber_list", "title")).to eq(update_params["title"])
        expect(JSON.parse(response.body).dig("subscriber_list", "description")).to eq(update_params["description"])
      end
    end

    context "for an unknown subscriber list" do
      let(:slug) { "not-a-real-slug" }

      it "returns 404" do
        patch update_subscriber_lists_path, params: update_params.to_json, headers: json_headers
        expect(response.status).to eq(404)
      end
    end
  end

  context "without authentication" do
    it "returns 401" do
      without_login do
        patch update_subscriber_lists_path, params: update_params.to_json, headers: json_headers
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns 403" do
      login_with_signin
      patch update_subscriber_lists_path, params: update_params.to_json, headers: json_headers

      expect(response.status).to eq(403)
    end
  end
end

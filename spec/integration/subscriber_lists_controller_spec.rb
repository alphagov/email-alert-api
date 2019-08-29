RSpec.describe "Getting a subscriber list", type: :request do
  describe "GET /subscriber-lists/<govuk_delivery_id>" do
    context "with authentication and authorisation" do
      before do
        login_with_internal_app
      end

      context "the subscriber_list exists" do
        let!(:subscriber_list) { create(:subscriber_list, slug: "test135") }

        it "returns it" do
          get "/subscriber-lists/test135"

          subscriber_list_response = JSON.parse(response.body).deep_symbolize_keys[:subscriber_list]

          expect(subscriber_list_response[:id]).to eq(subscriber_list.id)
        end
      end

      context "the subscriber_list doesn't exist" do
        it "returns a 404" do
          get "/subscriber-lists/test135"

          expect(response.status).to eq(404)
        end
      end

      context "creating subscriber list with a given slug" do
        it "returns a 201" do
          post "/subscriber-lists", params: {
            title: "General title",
            slug: "some-concatenated-slug",
            tags: { "brexit_checklist_criteria" => { "any" => %w[some-value] } }
          }

          expect(response.status).to eq(201)

          subscriber_list = JSON.parse(response.body)['subscriber_list']
          expect(subscriber_list['slug']).to eq("some-concatenated-slug")
          expect(subscriber_list['title']).to eq("General title")
        end
      end

      context "creating subscriber list with a description" do
        it "returns a 201" do
          post "/subscriber-lists", params: {
            title: "General title",
            description: "Some description",
          }

          expect(response.status).to eq(201)

          subscriber_list = JSON.parse(response.body)['subscriber_list']
          expect(subscriber_list['description']).to eq("Some description")
        end
      end

      context "creating subscriber list with a content_id" do
        it "returns a 201" do
          post "/subscriber-lists", params: {
            title: "General title",
            content_id: "71a573cc-916c-4724-9ab7-758e4637e537",
          }

          expect(response.status).to eq(201)

          subscriber_list = JSON.parse(response.body)['subscriber_list']
          expect(subscriber_list["content_id"]).to eq("71a573cc-916c-4724-9ab7-758e4637e537")
        end
      end
    end

    context "without authentication" do
      it "returns a 401" do
        without_login do
          get "/subscriber-lists/test135"
          expect(response.status).to eq(401)
        end
      end
    end

    context "without authorisation" do
      it "returns a 403" do
        login_with_signin

        get "/subscriber-lists/test135"

        expect(response.status).to eq(403)
      end
    end
  end
end

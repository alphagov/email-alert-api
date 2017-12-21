RSpec.describe "Getting a subscribable", type: :request do
  describe "GET /subscribables/<govuk_delivery_id>" do
    context "with authentication and authorisation" do
      before do
        login_with_internal_app
      end

      context "the subscribable exists" do
        let!(:subscribable) { create(:subscriber_list, gov_delivery_id: "test135") }

        it "returns it" do
          get "/subscribables/test135"

          subscribable_response = JSON.parse(response.body).deep_symbolize_keys[:subscribable]

          expect(subscribable_response[:id]).to eq(subscribable.id)
        end
      end

      context "the subscribable doesn't exist" do
        it "returns a 404" do
          get "/subscribables/test135"

          expect(response.status).to eq(404)
        end
      end
    end

    context "without authentication" do
      it "returns a 403" do
        get "/subscribables/test135"

        expect(response.status).to eq(403)
      end
    end

    context "without authorisation" do
      it "returns a 403" do
        login_with_signin

        get "/subscribables/test135"

        expect(response.status).to eq(403)
      end
    end
  end
end

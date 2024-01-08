require "gds_api/test_helpers/content_store"

RSpec.describe "Show subscriber list metrics", type: :request do
  include GdsApi::TestHelpers::ContentStore

  describe "GET /subscriber-lists/metrics/*path" do
    context "with authentication and authorisation" do
      before do
        login_with_internal_app
      end

      context "the subscriber_list exists and is empty" do
        let!(:subscriber_list) { create(:subscriber_list, url: "/metrictest") }

        it "returns the metrics with zeros" do
          stub_content_store_has_item(subscriber_list.url)
          get "/subscriber-lists/metrics/metrictest"

          expect(response.status).to eq(200)

          subscriber_list_metrics_response = JSON.parse(response.body)

          expect(subscriber_list_metrics_response["subscriber_list_count"]).to eq(0)
          expect(subscriber_list_metrics_response["all_notify_count"]).to eq(0)
        end
      end

      context "the subscriber_list exists and has subscribers" do
        let!(:subscriber_list) { create(:subscriber_list, :for_single_page_subscription) }

        it "returns the metrics with values" do
          stub_content_store_has_item(subscriber_list.url)
          get "/subscriber-lists/metrics#{subscriber_list.url}"

          expect(response.status).to eq(200)

          subscriber_list_metrics_response = JSON.parse(response.body)

          expect(subscriber_list_metrics_response["subscriber_list_count"]).to eq(subscriber_list.subscriptions.active.count)
          expect(subscriber_list_metrics_response["all_notify_count"]).to eq(0)
        end
      end

      context "the subscriber_list exists and has subscribers and also matches a link subscriber list" do
        let!(:subscriber_list) { create(:subscriber_list, :for_single_page_subscription) }
        let!(:tags_list) { create(:subscriber_list, links: { people: { any: %w[854440e9-c0f1-11e4-8223-005056011aef] } }) }
        let!(:subscription) { create(:subscription, subscriber_list: tags_list) }
        let!(:content_item) do
          content_item_for_base_path(subscriber_list.url).merge(
            "links" => { "people" => [{ "content_item" => "854440e9-c0f1-11e4-8223-005056011aef" }] },
            "locale" => "en",
            "details" => { "change_history" => [{ "note" => "changed!", "public_timestamp" => Time.zone.now }] },
          )
        end

        it "returns the metrics with zeros" do
          stub_content_store_has_item(subscriber_list.url, content_item)
          get "/subscriber-lists/metrics#{subscriber_list.url}"

          expect(response.status).to eq(200)

          subscriber_list_metrics_response = JSON.parse(response.body)

          expect(subscriber_list_metrics_response["subscriber_list_count"]).to eq(subscriber_list.subscriptions.active.count)
          expect(subscriber_list_metrics_response["all_notify_count"]).to eq(tags_list.subscriptions.active.count)
        end
      end

      context "the subscriber_list doesn't exist" do
        it "returns the metrics with zeros" do
          stub_content_store_has_item("/metrictest")
          get "/subscriber-lists/metrics/metrictest"

          expect(response.status).to eq(200)

          subscriber_list_metrics_response = JSON.parse(response.body)

          expect(subscriber_list_metrics_response["subscriber_list_count"]).to eq(0)
          expect(subscriber_list_metrics_response["all_notify_count"]).to eq(0)
        end
      end
    end

    context "without authentication" do
      it "returns a 401" do
        without_login do
          get "/subscriber-lists/metrics/metrictest"
          expect(response.status).to eq(401)
        end
      end
    end

    context "without authorisation" do
      it "returns a 403" do
        login_with_signin

        get "/subscriber-lists/metrics/metrictest"

        expect(response.status).to eq(403)
      end
    end
  end
end

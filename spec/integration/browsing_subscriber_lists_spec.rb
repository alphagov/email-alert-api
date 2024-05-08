RSpec.describe "Browsing subscriber lists", type: :request do
  describe "GET /subscriber-lists" do
    context "with authentication and authorisation" do
      before do
        login_with_internal_app
      end

      let(:uuid) { SecureRandom.uuid }

      let!(:subscriber_list_links_only) do
        create(
          :subscriber_list,
          links: {
            taxon_tree: { any: [uuid, "96d2db38-2ddd-4a3c-b9b4-11e310c8f256"] },
          },
          tags: {},
          document_type: "",
        )
      end

      let!(:subscriber_list_tags_only) do
        create(
          :subscriber_list,
          links: {},
          tags: {
            tribunal_decision_categories: { any: %w[transfer-of-undertakings time-to-train] },
          },
          document_type: "",
        )
      end

      let!(:subscriber_list_document_type_only) do
        create(
          :subscriber_list,
          links: {},
          tags: {},
          document_type: "travel_advice",
        )
      end

      let!(:subscriber_list_links_and_document_type) do
        create(
          :subscriber_list,
          links: {
            taxon_tree: { any: %w[642f0671-8521-4210-91d4-9c9c0e4e2187] },
          },
          tags: {},
          document_type: "tax",
        )
      end

      it "responds with the matching subscriber list" do
        get_subscriber_list(links: { taxon_tree: { any: [uuid, "96d2db38-2ddd-4a3c-b9b4-11e310c8f256"] } })
        database_subscriber_list = subscriber_list_links_only

        expect(response_subscriber_list).to include(
          id: database_subscriber_list.id,
          links: database_subscriber_list.links,
          tags: database_subscriber_list.tags,
          document_type: database_subscriber_list.document_type,
          slug: database_subscriber_list.slug,
          title: database_subscriber_list.title,
        )
      end

      it "finds subscriber lists that match all of the links" do
        get_subscriber_list(links: { taxon_tree: { any: [uuid, "96d2db38-2ddd-4a3c-b9b4-11e310c8f256"] } })
        expect(response.status).to eq(200)
        expect(response_subscriber_list[:id]).to eq(subscriber_list_links_only.id)
      end

      it "finds subscriber lists that match all of the tags" do
        get_subscriber_list(tags: { tribunal_decision_categories: { any: %w[time-to-train transfer-of-undertakings] } })
        expect(response.status).to eq(200)
        expect(response_subscriber_list[:id]).to eq(subscriber_list_tags_only.id)
      end

      it "finds subscriber lists that match document type only" do
        get_subscriber_list(document_type: "travel_advice")
        expect(response.status).to eq(200)
        expect(response_subscriber_list[:id]).to eq(subscriber_list_document_type_only.id)
      end

      it "finds subscriber lists that match links and document type" do
        get_subscriber_list(
          links: { taxon_tree: { any: %w[642f0671-8521-4210-91d4-9c9c0e4e2187] } },
          document_type: "tax",
        )
        expect(response.status).to eq(200)
        expect(response_subscriber_list[:id]).to eq(subscriber_list_links_and_document_type.id)
      end

      it "does not find subscriber lists when no query keys are provided" do
        get_subscriber_list({})
        expect(response.status).to eq(404)
      end

      it "copes if the (legacy) links / tags are not in a hash" do
        get_subscriber_list(links: { taxon_tree: [uuid, "96d2db38-2ddd-4a3c-b9b4-11e310c8f256"] })
        expect(response_subscriber_list[:id]).to eq(subscriber_list_links_only.id)

        get_subscriber_list(tags: { tribunal_decision_categories: %w[time-to-train transfer-of-undertakings] })
        expect(response_subscriber_list[:id]).to eq(subscriber_list_tags_only.id)
      end
    end

    context "without authentication" do
      it "returns a 401" do
        without_login do
          get_subscriber_list({})
          expect(response.status).to eq(401)
        end
      end
    end

    context "without authorisation" do
      it "returns a 403" do
        login_with_signin
        get_subscriber_list({})
        expect(response.status).to eq(403)
      end
    end

    def get_subscriber_list(query_payload)
      get "/subscriber-lists", params: query_payload, headers: json_headers
    end

    def response_subscriber_list
      JSON.parse(response.body).fetch("subscriber_list").deep_symbolize_keys
    end
  end
end

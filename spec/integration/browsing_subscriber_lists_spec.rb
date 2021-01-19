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
            topics: { any: [uuid, "drug-device-alert"] },
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
            topics: { any: ["oil-and-gas/licensing", "drug-device-alert"] },
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
            topics: { any: %w[vat-rates] },
          },
          tags: {},
          document_type: "tax",
        )
      end

      let!(:subscriber_list_tags_and_document_type) do
        create(
          :subscriber_list,
          links: {},
          tags: {
            topics: { any: %w[vat-rates] },
          },
          document_type: "tax",
        )
      end

      it "responds with the matching subscriber list" do
        get_subscriber_list(links: { topics: { any: [uuid, "drug-device-alert"] } })

        database_subscriber_list = subscriber_list_links_only
        response_subscriber_list = JSON.parse(response.body).fetch("subscriber_list").deep_symbolize_keys

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
        get_subscriber_list(links: { topics: { any: [uuid, "drug-device-alert"] } })
        expect(response.status).to eq(200)

        subscriber_list = JSON.parse(response.body).fetch("subscriber_list")
        expect(subscriber_list.fetch("id")).to eq(subscriber_list_links_only.id)
      end

      it "finds subscriber lists that match all of the tags" do
        get_subscriber_list(tags: { topics: { any: ["drug-device-alert", "oil-and-gas/licensing"] } })
        expect(response.status).to eq(200)

        subscriber_list = JSON.parse(response.body).fetch("subscriber_list")
        expect(subscriber_list.fetch("id")).to eq(subscriber_list_tags_only.id)
      end

      it "finds subscriber lists that match document type only" do
        get_subscriber_list(document_type: "travel_advice")
        expect(response.status).to eq(200)

        subscriber_list = JSON.parse(response.body).fetch("subscriber_list")
        expect(subscriber_list.fetch("id")).to eq(subscriber_list_document_type_only.id)
      end

      it "finds subscriber lists that match links and document type" do
        get_subscriber_list(
          links: { topics: { any: %w[vat-rates] } },
          document_type: "tax",
        )
        expect(response.status).to eq(200)

        subscriber_list = JSON.parse(response.body).fetch("subscriber_list")
        expect(subscriber_list.fetch("id")).to eq(subscriber_list_links_and_document_type.id)
      end

      it "finds subscriber lists that match tags and document type" do
        get_subscriber_list(
          tags: { topics: { any: %w[vat-rates] } },
          document_type: "tax",
        )
        expect(response.status).to eq(200)

        subscriber_list = JSON.parse(response.body).fetch("subscriber_list")
        expect(subscriber_list.fetch("id")).to eq(subscriber_list_tags_and_document_type.id)
      end

      it "does not find subscriber lists that match some of the links" do
        get_subscriber_list(links: { topics: { any: %w[drug-device-alert] } })
        expect(response.status).to eq(404)
      end

      it "does not find subscriber lists that match some of the tags" do
        get_subscriber_list(tags: { topics: { any: %w[drug-device-alert] } })
        expect(response.status).to eq(404)
      end

      it "does not find subscriber lists that with a different document type" do
        get_subscriber_list(document_type: "something_else")
        expect(response.status).to eq(404)
      end

      it "does not find subscriber lists that match links but not document type" do
        get_subscriber_list(links: { topics: { any: %w[vat-rates] } })
        expect(response.status).to eq(404)
      end

      it "does not find subscriber lists that match document type but not links" do
        get_subscriber_list(document_type: "tax")
        expect(response.status).to eq(404)
      end

      it "does not find subscriber lists that match tags but not document type" do
        get_subscriber_list(tags: { topics: { any: %w[vat-rates] } })
        expect(response.status).to eq(404)
      end

      it "does not find subscriber lists that match document type but not tags" do
        get_subscriber_list(document_type: "tax")
        expect(response.status).to eq(404)
      end

      it "does not find subscriber lists when no query keys are provided" do
        get_subscriber_list({})
        expect(response.status).to eq(404)
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
  end
end

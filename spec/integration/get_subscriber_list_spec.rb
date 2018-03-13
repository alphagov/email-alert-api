RSpec.describe "Getting a subscriber list", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    let!(:subscriber_list_links_only) do
      create(
        :subscriber_list,
        links: {
          topics: ["oil-and-gas/licensing", "drug-device-alert"]
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
          topics: ["oil-and-gas/licensing", "drug-device-alert"]
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
          topics: ["vat-rates"],
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
          topics: ["vat-rates"],
        },
        document_type: "tax",
      )
    end

    it "responds with the matching subscriber list" do
      get_subscriber_list(links: { topics: ["drug-device-alert", "oil-and-gas/licensing"] })

      database_subscriber_list = subscriber_list_links_only
      response_subscriber_list = JSON.parse(response.body).fetch("subscriber_list").deep_symbolize_keys

      expect(response_subscriber_list).to include(
        id: database_subscriber_list.id,
        links: database_subscriber_list.links,
        tags: database_subscriber_list.tags,
        document_type: database_subscriber_list.document_type,
        gov_delivery_id: database_subscriber_list.gov_delivery_id,
        subscription_url: database_subscriber_list.subscription_url,
        title: database_subscriber_list.title,
      )
    end

    it "finds subscriber lists that match all of the links" do
      get_subscriber_list(links: { topics: ["drug-device-alert", "oil-and-gas/licensing"] })
      expect(response.status).to eq(200)

      subscriber_list = JSON.parse(response.body).fetch("subscriber_list")
      expect(subscriber_list.fetch("id")).to eq(subscriber_list_links_only.id)
    end

    it "finds subscriber lists that match all of the tags" do
      get_subscriber_list(tags: { topics: ["drug-device-alert", "oil-and-gas/licensing"] })
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
        links: { topics: ["vat-rates"] },
        document_type: "tax",
      )
      expect(response.status).to eq(200)

      subscriber_list = JSON.parse(response.body).fetch("subscriber_list")
      expect(subscriber_list.fetch("id")).to eq(subscriber_list_links_and_document_type.id)
    end

    it "finds subscriber lists that match tags and document type" do
      get_subscriber_list(
        tags: { topics: ["vat-rates"] },
        document_type: "tax",
      )
      expect(response.status).to eq(200)

      subscriber_list = JSON.parse(response.body).fetch("subscriber_list")
      expect(subscriber_list.fetch("id")).to eq(subscriber_list_tags_and_document_type.id)
    end

    it "does not find subscriber lists that match some of the links" do
      get_subscriber_list(links: { topics: ["drug-device-alert"] })
      expect(response.status).to eq(404)
    end

    it "does not find subscriber lists that match some of the tags" do
      get_subscriber_list(tags: { topics: ["drug-device-alert"] })
      expect(response.status).to eq(404)
    end

    it "does not find subscriber lists that with a different document type" do
      get_subscriber_list(document_type: "something_else")
      expect(response.status).to eq(404)
    end

    it "does not find subscriber lists that match links but not document type" do
      get_subscriber_list(links: { topics: ["vat-rates"] })
      expect(response.status).to eq(404)
    end

    it "does not find subscriber lists that match document type but not links" do
      get_subscriber_list(document_type: "tax")
      expect(response.status).to eq(404)
    end

    it "does not find subscriber lists that match tags but not document type" do
      get_subscriber_list(tags: { topics: ["vat-rates"] })
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

    context "when passing in gov_delivery_id" do
      it "does not find a subscriber list of the gov_delivery_id does not match" do
        get_subscriber_list(
          tags: { topics: ["vat-rates"] },
          document_type: "tax",
          gov_delivery_id: "NEW-TOPIC"
        )
        expect(response.status).to eq(404)
      end

      it "finds the subscriber list if the gov_delivery_id matches" do
        _alpha = create(:subscriber_list, tags: { topics: ["vat-rates"] }, slug: "alpha")
        beta = create(:subscriber_list, tags: { topics: ["vat-rates"] }, slug: "beta")
        _gamma = create(:subscriber_list, tags: { topics: ["vat-rates"] }, slug: "gamma")

        get_subscriber_list(
          tags: { topics: ["vat-rates"] },
          gov_delivery_id: "beta"
        )
        expect(response.status).to eq(200)

        subscriber_list = JSON.parse(response.body).fetch("subscriber_list")
        expect(subscriber_list.fetch("id")).to eq(beta.id)
      end
    end
  end

  context "without authentication" do
    it "returns a 403" do
      get_subscriber_list({})
      expect(response.status).to eq(403)
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
    get "/subscriber-lists", params: query_payload, headers: JSON_HEADERS
  end
end

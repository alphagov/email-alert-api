RSpec.describe "Creating a subscriber list", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    it "creates a subscriber_list" do
      create_subscriber_list(tags: { topics: ["oil-and-gas/licensing"] })

      expect(SubscriberList.count).to eq(1)
    end

    it "returns a 201" do
      create_subscriber_list(tags: { topics: ["oil-and-gas/licensing"] })

      expect(response.status).to eq(201)
    end

    context "with an existing subsciber list with the same slug" do
      before do
        create(:subscriber_list, slug: "oil-and-gas")
      end

      it "creates another subscriber list with a different slug" do
        create_subscriber_list(title: "oil and gas", tags: { topics: ["oil-and-gas/licensing"] })

        expect(response.status).to eq(201)

        response_hash = JSON.parse(response.body)
        subscriber_list = response_hash["subscriber_list"]
        expect(subscriber_list["gov_delivery_id"]).to eq("oil-and-gas-2")
      end
    end

    it "returns the created subscriber list" do
      create_subscriber_list(
        title: "oil and gas licensing",
        tags: { topics: ["oil-and-gas/licensing"] },
        links: { topics: ["uuid-888"] }
      )
      response_hash = JSON.parse(response.body)
      subscriber_list = response_hash["subscriber_list"]

      expect(subscriber_list.keys.to_set).to eq(
        %w{
          id
          title
          slug
          document_type
          subscription_url
          gov_delivery_id
          created_at
          updated_at
          tags
          links
          email_document_supertype
          government_document_supertype
        }.to_set
      )

      expect(subscriber_list).to include(
        "tags" => {
          "topics" => ["oil-and-gas/licensing"]
        },
        "links" => {
          "topics" => ["uuid-888"]
        }
      )

      expect(subscriber_list["gov_delivery_id"]).to eq("oil-and-gas-licensing")
      expect(subscriber_list["slug"]).to eq("oil-and-gas-licensing")
    end

    it "returns an error if tag isn't an array" do
      create_subscriber_list(
        tags: { topics: "oil-and-gas/licensing" },
      )

      expect(response.status).to eq(422)
    end

    it "returns an error if creating the same topic" do
      create_subscriber_list(title: "oil and gas", tags: { topics: ["oil-and-gas/licensing"] })
      create_subscriber_list(title: "oil and gas", tags: { topics: ["oil-and-gas/licensing"] })

      expect(response.status).to eq(422)
    end

    it "returns an error if link isn't an array" do
      create_subscriber_list(
        links: { topics: "uuid-888" },
      )

      expect(response.status).to eq(422)
    end

    describe "creating a subscriber list with a document_type" do
      it "returns a 201" do
        create_subscriber_list(document_type: "travel_advice")

        expect(response.status).to eq(201)
      end

      it "sets the document_type on the subscriber list" do
        create_subscriber_list(
          tags: { countries: ["andorra"] },
          document_type: "travel_advice"
        )

        subscriber_list = SubscriberList.last
        expect(subscriber_list.document_type).to eq("travel_advice")
      end
    end

    context "when creating a subscriber list with no tags or links" do
      context "and a document_type is provided" do
        it "returns a 201" do
          create_subscriber_list(document_type: "travel_advice")

          expect(response.status).to eq(201)
        end
      end
    end

    context "when creating a subscriber list with 'email' and 'government' document supertypes" do
      it "returns a 201" do
        create_subscriber_list(
          email_document_supertype: "publications",
          government_document_supertype: "news_stories",
        )

        expect(response.status).to eq(201)

        expect(SubscriberList.last).to have_attributes(
          email_document_supertype: "publications",
          government_document_supertype: "news_stories",
        )
      end
    end

    def create_subscriber_list(payload = {})
      defaults = {
        title: "This is a sample title",
        tags: {},
        links: {},
      }

      request_body = JSON.dump(defaults.merge(payload))

      post "/subscriber-lists", params: request_body, headers: JSON_HEADERS
    end
  end

  context "without authentication" do
    it "returns a 403" do
      post "/subscriber-lists", params: {}, headers: {}
      expect(response.status).to eq(403)
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      post "/subscriber-lists", params: {}, headers: {}
      expect(response.status).to eq(403)
    end
  end
end

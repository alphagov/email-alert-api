RSpec.describe "Creating a subscriber list", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    it "creates a subscriber_list" do
      create_subscriber_list(tags: { topics: { any: ["oil-and-gas/licensing"] },
                                     location: { all: %w[france germany] } })

      expect(SubscriberList.count).to eq(1)
    end

    it "returns a 201" do
      create_subscriber_list(tags: { topics: { any: ["oil-and-gas/licensing"] },
                                     location: { all: %w[france germany] } })

      expect(response.status).to eq(201)
    end

    it "returns the created subscriber list" do
      create_subscriber_list(
        title: "oil and gas licensing",
        tags: { topics: { any: ["oil-and-gas/licensing"] } },
        links: { topics: { any: %w[uuid-888] },
                 taxon_tree: { all: %w[taxon1 taxon2] } }
      )
      response_hash = JSON.parse(response.body)
      subscriber_list = response_hash["subscriber_list"]

      expect(subscriber_list.keys.to_set.sort).to eq(
        %w{
          id
          title
          slug
          description
          document_type
          subscription_url
          gov_delivery_id
          created_at
          updated_at
          url
          tags
          links
          list_group_id
          email_document_supertype
          government_document_supertype
          active_subscriptions_count
        }.to_set.sort
      )

      expect(subscriber_list).to include(
        "tags" => {
          "topics" => {
            "any" => ["oil-and-gas/licensing"]
          }
        },
        "links" => {
          "topics" => {
            "any" => %w[uuid-888],
          },
          "taxon_tree" => {
            "all" => %w[taxon1 taxon2]
          }
        }
      )

      expect(subscriber_list["gov_delivery_id"]).to eq("oil-and-gas-licensing")
      expect(subscriber_list["slug"]).to eq("oil-and-gas-licensing")
    end

    it "can create a subscriber_list with a url" do
      create_subscriber_list(tags: { topics: { any: ["oil-and-gas/licensing"] },
                                     location: { all: %w[france germany] } },
                             url: "/oil-and-gas")

      expect(SubscriberList.count).to eq(1)
      expect(SubscriberList.first.url).to eq("/oil-and-gas")
    end

    context "with an existing subscriber list with the same slug" do
      before do
        create(:subscriber_list, slug: "oil-and-gas")
      end

      it "creates another subscriber list with a different slug" do
        create_subscriber_list(title: "oil and gas", tags: { topics: { any: ["oil-and-gas/licensing"] } })

        expect(response.status).to eq(201)

        response_hash = JSON.parse(response.body)
        subscriber_list = response_hash["subscriber_list"]
        expect(subscriber_list["gov_delivery_id"]).to eq("oil-and-gas-2")
      end
    end

    context 'when using legacy parameters' do
      it 'creates a new subscriber list' do
        expect {
          create_subscriber_list(
            title: "oil and gas licensing",
            links: { topics: %w[uuid-888] }
          )
        }.to change { SubscriberList.count }.by(1)
      end

      it "returns an error if link isn't an array" do
        create_subscriber_list(
          links: { topics: "uuid-888" },
          )

        expect(response.status).to eq(422)
      end
    end

    context "when creating a subscriber list with a document_type" do
      it "returns a 201" do
        create_subscriber_list(document_type: "travel_advice")

        expect(response.status).to eq(201)
      end

      it "sets the document_type on the subscriber list" do
        create_subscriber_list(
          tags: { location: { any: %w[andorra] } },
          document_type: "travel_advice"
        )

        subscriber_list = SubscriberList.last
        expect(subscriber_list.document_type).to eq("travel_advice")
      end
    end

    context "when creating a subscriber list with content_purpose_subgroup" do
      it "returns a 201" do
        create_subscriber_list(tags: { content_purpose_subgroup: { any: %w[news] } })

        expect(response.status).to eq(201)
      end

      it "sets content_purpose_subgroup on the subscriber list" do
        create_subscriber_list(
          tags: {
            location: { any: %w[andorra] },
            content_purpose_subgroup: { any: %w[news] }
          }
        )

        subscriber_list = SubscriberList.last
        expect(subscriber_list.tags[:content_purpose_subgroup]).to eq(any: %w[news])
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

    context "creating subscriber list with a list_group_id" do
      @list_group_id = SecureRandom.uuid
      it "returns a 201" do
        post "/subscriber-lists", params: {
          title: "General title",
          description: "Some description",
          list_group_id: @list_group_id,
        }

        expect(response.status).to eq(201)

        subscriber_list = JSON.parse(response.body)['subscriber_list']
        expect(subscriber_list['list_group_id']).to eq(@list_group_id)
      end
    end

    context "an invalid subscriber list" do
      it "returns 422" do
        post "/subscriber-lists", params: {
          title: "",
          description: "Some description",
        }

        expect(response.status).to eq(422)

        expect(JSON.parse(response.body)).to match(
          "error" => "Unprocessable Entity",
          "details" => { "title" => ["can't be blank"] }
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
    it "returns a 401" do
      without_login do
        post "/subscriber-lists", params: {}, headers: {}
        expect(response.status).to eq(401)
      end
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

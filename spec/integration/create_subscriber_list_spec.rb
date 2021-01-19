RSpec.describe "Creating a subscriber list", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    it "creates a subscriber_list" do
      create_subscriber_list
      expect(SubscriberList.count).to eq(1)
    end

    it "returns a 200" do
      create_subscriber_list
      expect(response.status).to eq(200)
    end

    it "returns the created subscriber list" do
      create_subscriber_list
      response_hash = JSON.parse(response.body)
      subscriber_list = response_hash["subscriber_list"]

      expect(subscriber_list.keys.to_set.sort).to eq(
        %w[
          id
          title
          slug
          document_type
          created_at
          updated_at
          url
          tags
          links
          email_document_supertype
          government_document_supertype
          active_subscriptions_count
          tags_digest
          links_digest
        ].to_set.sort,
      )

      expect(subscriber_list).to include(
        "tags" => {
          "topics" => {
            "any" => ["oil-and-gas/licensing"],
          },
          "location" => {
            "all" => %w[france germany],
          },
        },
        "links" => {
          "topics" => {
            "any" => %w[uuid-888],
          },
          "taxon_tree" => {
            "all" => %w[taxon1 taxon2],
          },
        },
      )

      expect(subscriber_list["slug"]).to eq("this-is-a-sample-title")
      expect(subscriber_list["links_digest"]).to eq(digested(subscriber_list["links"]))
      expect(subscriber_list["tags_digest"]).to eq(digested(subscriber_list["tags"]))
    end

    context "an existing subscriber list" do
      it "returns the existing list" do
        2.times.each { create_subscriber_list }
        expect(SubscriberList.count).to eq(1)
        expect(response.status).to eq(200)
        expect(response.body).to include("subscriber_list")
      end
    end

    context "an invalid subscriber list" do
      it "returns 422" do
        post "/subscriber-lists", params: { title: "" }
        expect(response.status).to eq(422)

        expect(JSON.parse(response.body)).to match(
          "error" => "Unprocessable Entity",
          "details" => { "title" => ["can't be blank"] },
        )
      end
    end

    def create_subscriber_list(payload = {})
      defaults = {
        title: "This is a sample title",
        tags: {
          topics: { any: ["oil-and-gas/licensing"] },
          location: { all: %w[france germany] },
        },
        links: {
          topics: { any: %w[uuid-888] },
          taxon_tree: { all: %w[taxon1 taxon2] },
        },
      }

      request_body = JSON.dump(defaults.merge(payload))
      post "/subscriber-lists", params: request_body, headers: json_headers
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

  def digested(hash)
    HashDigest.new(hash).generate
  end
end

RSpec.describe "Creating a subscriber list", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    it "returns the created subscriber list" do
      create_subscriber_list
      expect(response.status).to eq(200)

      expect(SubscriberList.count).to eq(1)
      subscriber_list = response_subscriber_list

      expect(subscriber_list.keys).to include(
        "id", "title", "slug", "document_type",
        "tags", "links"
      )

      expect(subscriber_list).to include(
        "tags" => {
          "tribunal_decision_categories" => {
            "any" => %w[transfer-of-undertakings],
          },
          "location" => {
            "all" => %w[france germany],
          },
        },
        "links" => {
          "organisations" => {
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

    context "with legacy links / tags" do
      it "converts them to a nested hash" do
        create_subscriber_list(
          tags: { location: %w[france germany] },
          links: { organisations: %w[uuid-888] },
        )

        expect(response_subscriber_list).to include(
          "tags" => {
            "location" => {
              "any" => %w[france germany],
            },
          },
          "links" => {
            "organisations" => {
              "any" => %w[uuid-888],
            },
          },
        )
      end
    end

    context "with content_id" do
      it "returns the content subscriber list by content_id" do
        create_subscriber_list(
          { "content_id": "7c615f50-d48e-47a9-82be-6181559198ed" },
        )
        expect(response.status).to eq(200)

        expect(SubscriberList.count).to eq(1)

        expect(response_subscriber_list).to include(
          "content_id" => "7c615f50-d48e-47a9-82be-6181559198ed",
        )
      end
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

    context "with a description" do
      it "returns a list with a description" do
        create_subscriber_list(
          { "description": "A description" },
        )

        expect(response.status).to eq(200)
        expect(response_subscriber_list).to include(
          "description" => "A description",
        )
      end
    end

    def create_subscriber_list(payload = {})
      defaults = {
        title: "This is a sample title",
        tags: {
          tribunal_decision_categories: { any: %w[transfer-of-undertakings] },
          location: { all: %w[france germany] },
        },
        links: {
          organisations: { any: %w[uuid-888] },
          taxon_tree: { all: %w[taxon1 taxon2] },
        },
      }

      request_body = JSON.dump(defaults.merge(payload))
      post "/subscriber-lists", params: request_body, headers: json_headers
    end

    def response_subscriber_list
      JSON.parse(response.body).fetch("subscriber_list")
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

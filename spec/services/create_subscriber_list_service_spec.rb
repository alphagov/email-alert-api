RSpec.describe CreateSubscriberListService do
  describe ".call" do
    let(:user) { create :user }

    let(:params) do
      ActionController::Parameters.new(
        title: "This is a sample title",
        tags: { topics: { any: %w[oil-and-gas/licensing] } },
        links: { taxon_tree: { any: %w[uuid] } },
        url: "/oil-and-gas",
        document_type: "travel_advice",
        email_document_supertype: "publications",
        government_document_supertype: "news_stories",
      )
    end

    let(:list) do
      described_class.call(params: params, user: user)
    end

    context "with all of the possible params" do
      it "creates a list with the given params" do
        expect(list.title).to eq("This is a sample title")
        expect(list.url).to eq("/oil-and-gas")
        expect(list.document_type).to eq("travel_advice")
        expect(list.email_document_supertype).to eq("publications")
        expect(list.government_document_supertype).to eq("news_stories")
        expect(list.tags).to eq(topics: { any: ["oil-and-gas/licensing"] })
        expect(list.links).to match(taxon_tree: { any: %w[uuid] })
      end

      it "slugifies the list title" do
        expect(list.slug).to eq("this-is-a-sample-title")
      end

      it "digests the links and tags" do
        expect(list.tags_digest).to eq(HashDigest.new(list.tags).generate)
        expect(list.links_digest).to eq(HashDigest.new(list.links).generate)
      end
    end

    context "with minimal possible params" do
      let(:params) do
        ActionController::Parameters.new(title: "This is a sample title")
      end

      it "creates a list with the given params" do
        expect(list.tags).to eq({})
        expect(list.links).to eq({})
        expect(list.url).to be_nil
        expect(list.document_type).to eq("")
        expect(list.email_document_supertype).to eq("")
        expect(list.government_document_supertype).to eq("")
      end

      it "does not populate the digest for links / tags" do
        expect(list.tags_digest).to be_nil
        expect(list.links_digest).to be_nil
      end
    end

    context "when a slug is already in use" do
      before do
        create(:subscriber_list, slug: "this-is-a-sample-title")
      end

      it "makes sure the slug is unique" do
        expect(list.slug).to match(/this-is-a-sample-title-[a-z0-9]+/)
      end
    end
  end
end

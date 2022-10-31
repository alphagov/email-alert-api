RSpec.describe CreateSubscriberListService do
  describe ".call" do
    let(:user) { create :user }
    let(:existing_list_query) { double(FindExactQuery, exact_match: nil) }
    let(:title) { "This is a sample title" }
    let(:url) { "/oil-and-gas" }

    let(:matching_criteria) do
      {
        tags: { topics: { any: %w[oil-and-gas/licensing] } },
        links: { taxon_tree: { any: %w[uuid] } },
        document_type: "travel_advice",
        email_document_supertype: "publications",
        government_document_supertype: "news_stories",
      }
    end

    let(:list) do
      described_class.call(
        title:,
        url:,
        matching_criteria:,
        user:,
      )
    end

    before do
      allow(FindExactQuery).to receive(:new).with(
        hash_including(
          tags: a_kind_of(Hash),
          links: a_kind_of(Hash),
          document_type: a_kind_of(String),
          email_document_supertype: a_kind_of(String),
          government_document_supertype: a_kind_of(String),
        ),
      )
      .and_return(existing_list_query)
    end

    context "when a matching list exists" do
      let(:existing_list) do
        create(:subscriber_list, title: "other", url: "/other")
      end

      before do
        allow(existing_list_query).to receive(:exact_match)
          .and_return(existing_list)
      end

      it "returns early with that list" do
        expect(list).to eq(existing_list)
      end

      it "updates the title and url" do
        expect(list.title).to eq("This is a sample title")
        expect(list.url).to eq("/oil-and-gas")
      end
    end

    context "when an up-to-date list exists" do
      let(:existing_list) do
        create(:subscriber_list,
               title:,
               url:,
               updated_at: 2.days.ago.midnight)
      end

      before do
        allow(existing_list_query).to receive(:exact_match)
          .and_return(existing_list)
      end

      it "only updates if there is a change" do
        expect(list.updated_at).to eq(2.days.ago.midnight)
      end
    end

    context "with all of the possible params" do
      it "creates a list with the given params" do
        expect(list.title).to eq(title)
        expect(list.url).to eq(url)
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
      let(:url) { nil }

      let(:matching_criteria) do
        {
          links: {},
          tags: {},
          document_type: "",
          email_document_supertype: "",
          government_document_supertype: "",
        }
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

    context "when the list title is very long" do
      let(:title) { "long " * 1000 }

      it "truncates the slug to < 255 chars" do
        expect(list.slug).to match(/^long-long-long-/)
        expect(list.slug.length).to eq(254)
      end
    end
  end
end

RSpec.describe "Migrating users from one subscriber list to another", type: :request do
  it "requires a source slug paramater and a destination slug paramater" do
    post "/subscriber-lists/bulk-migrate"

    expect(response.status).to eq(422)
    expect(JSON.parse(response.body)["error"]).to eq "Must provide slugs for source and destination subscriber lists"
  end

  it "requires a valid source subscriber list" do
    subscriber_list = create(:subscriber_list)
    params = {
      "to_slug" => subscriber_list.slug,
      "from_slug" => "nothing-here",
    }
    post("/subscriber-lists/bulk-migrate", params:)

    expect(response.status).to eq(404)
    expect(JSON.parse(response.body)["error"]).to eq "Could not find source subscriber list"
  end

  it "requires a valid successor subscriber list" do
    subscriber_list = create(:subscriber_list)
    params = {
      "to_slug" => "nothing-here",
      "from_slug" => subscriber_list.slug,
    }
    post("/subscriber-lists/bulk-migrate", params:)

    expect(response.status).to eq(404)
    expect(JSON.parse(response.body)["error"]).to eq "Could not find destination subscriber list"
  end

  context "when both source and destination subscriber lists exist" do
    let!(:existing_subscription) { create(:subscription) }
    let(:subscriber) { existing_subscription.subscriber }
    let(:source_list) { existing_subscription.subscriber_list }
    let(:destination_list) { create(:subscriber_list) }
    let(:params) do
      {
        "to_slug" => destination_list.slug,
        "from_slug" => source_list.slug,
      }
    end
    it "migrates subscribers" do
      post("/subscriber-lists/bulk-migrate", params:)

      expect(existing_subscription.reload.ended_reason).to eq("bulk_migrated")
      expect(destination_list.subscribers.count).to eq 1
      expect(source_list.active_subscriptions_count).to eq 0
      expect(destination_list.subscribers).to include(subscriber)
      expect(source_list.subscriptions.active).not_to include(subscriber)
    end
  end
end

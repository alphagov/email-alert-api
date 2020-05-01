require "gds_api/test_helpers/content_store"

RSpec.describe "Sending an unpublish message", type: :request do
  include ::GdsApi::TestHelpers::ContentStore

  context "with authentication and authorisation" do
    before :each do
      content_id = SecureRandom.uuid

      subscriber = create(
        :subscriber,
        address: "test@example.com",
      )

      create(
        :subscriber,
        address: Email::COURTESY_EMAIL,
      )

      subscriber_list = create(
        :subscriber_list,
        links: { taxon_tree: { any: [content_id] } },
        title: "First Subscription",
      )

      @subscription = create(
        :subscription,
        subscriber: subscriber,
        subscriber_list: subscriber_list,
      )

      @request_params = { content_id: content_id,
                          redirects: [{ path: "/source/path", destination: "/redirected/path" }] }.to_json

      stub_content_store_has_item(
        "/redirected/path",
        {
          "base_path" => "/redirected/path",
          "title" => "redirected title",
        }.to_json,
      )
    end

    before do
      allow(DeliveryRequestService).to receive(:call)
      login_with_internal_app
      post "/unpublish-messages", params: @request_params, headers: json_headers
    end
    it "returns status 202" do
      expect(response.status).to eq(202)
    end
    it "creates an Email and a courtesy email" do
      expect(Email.count).to eq(2)
    end
    it "sends a message" do
      expect(DeliveryRequestService).to have_received(:call)
        .with(email: having_attributes(subject: "Update from GOV.UK – First Subscription",
                                       address: Email::COURTESY_EMAIL))
      expect(DeliveryRequestService).to have_received(:call)
        .with(email: having_attributes(subject: "Update from GOV.UK – First Subscription",
                                       address: "test@example.com"))
    end
    it "the message contains the redirect URL" do
      expect(DeliveryRequestService).to have_received(:call)
        .with(email: having_attributes(body: include("/redirected/path", "redirected title"))).twice
    end
    it "unsubscribes all affected subscriptions" do
      expect(@subscription.reload.ended_at).to_not be_nil
    end
  end
end

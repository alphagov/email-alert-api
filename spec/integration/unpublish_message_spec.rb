RSpec.describe "Sending an unpublish message", type: :request do
  context "with authentication and authorisation" do
    before :each do
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
        links: { taxon_tree: [SecureRandom.uuid] },
        title: "First Subscription",
      )

      @subscription = create(
        :subscription,
        subscriber: subscriber,
        subscriber_list: subscriber_list
      )

      @request_params = { content_id: subscriber_list.links.values.flatten.join }.to_json
    end

    before do
      allow(DeliveryRequestService).to receive(:call)
      login_with_internal_app
      post "/unpublish-messages", params: @request_params, headers: JSON_HEADERS
    end

    it "creates an Email and a courtesy email" do
      expect(Email.count).to eq(2)
    end
    it "sends a message" do
      expect(DeliveryRequestService).to have_received(:call).
        with(email: having_attributes(subject: 'First Subscription',
                                      address: Email::COURTESY_EMAIL))
      expect(DeliveryRequestService).to have_received(:call).
        with(email: having_attributes(subject: 'First Subscription',
                                      address: "test@example.com"))
    end
    it 'unsubscribes all affected subscriptions' do
      expect(@subscription.reload.ended_at).to_not be_nil
    end
  end
end

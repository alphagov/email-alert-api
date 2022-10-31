RSpec.describe "Creating a subscription", type: :request do
  let!(:subscriber_list) { create(:subscriber_list) }
  let!(:subscriber) { create(:subscriber, address: "test@example.com") }
  let(:address) { subscriber.address }
  let(:frequency) { "daily" }

  def create_subscription(extra_params: {})
    default_params = {
      subscriber_list_id: subscriber_list.id,
      address:,
      frequency:,
    }

    post "/subscriptions", params: default_params.merge(extra_params)
  end

  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    it "requires an address parameter" do
      post "/subscriptions", params: { subscriber_list_id: 10 }
      expect(response.status).to eq(400)
    end

    it "requires a subscriber_list_id parameter" do
      post "/subscriptions", params: { address: "test@example.com" }
      expect(response.status).to eq(400)
    end

    it "returns status code 404 if the subscriber list doesn't exist" do
      post "/subscriptions", params: { subscriber_list_id: 10, address: "test@example.com" }
      expect(response.status).to eq(404)
    end

    context "with an existing subscription with different frequency" do
      let!(:subscription) { create(:subscription, subscriber_list:, subscriber:, frequency: :immediately) }

      it "creates a new subscription" do
        expect { create_subscription }.to change(Subscription, :count)
      end

      it "returns status code 200" do
        create_subscription
        expect(response.status).to eq(200)
      end

      it "returns the new subscription" do
        create_subscription
        expect(data[:id]).to_not eq(subscription.id)
        expect(data[:subscription][:frequency]).to eq frequency
      end

      it "marks the existing subscription as ended" do
        create_subscription
        expect(subscription.reload.ended?).to be true
      end

      it "sends a confirmation email" do
        stub_notify
        create_subscription
        expect(a_request(:post, /notifications/)).to have_been_made.at_least_once
      end
    end

    context "with a parameter to skip sending the confirmation email" do
      it "does not send a confirmation email" do
        stub_notify
        create_subscription(extra_params: { skip_confirmation_email: true })
        expect(a_request(:post, /notifications/)).to_not have_been_made
      end

      it "returns status code 200" do
        create_subscription(extra_params: { skip_confirmation_email: true })
        expect(response.status).to eq(200)
      end
    end

    context "with an existing subscription with identical frequency" do
      let!(:subscription) { create(:subscription, subscriber_list:, subscriber:, frequency:) }

      it "does not create a new subscription" do
        expect { create_subscription }.to_not change(Subscription, :count)
      end

      it "returns status code 200" do
        create_subscription
        expect(response.status).to eq(200)
      end

      it "returns the existing subscription" do
        create_subscription
        expect(data[:subscription][:id]).to eq(subscription.id)
        expect(data[:subscription][:frequency]).to eq frequency
      end

      it "does not mark the existing subscription as ended" do
        create_subscription
        expect(subscription.reload.ended?).to be false
      end

      it "sends a confirmation email" do
        stub_notify
        create_subscription
        expect(a_request(:post, /notifications/)).to have_been_made.at_least_once
      end
    end

    context "with an existing subscriber" do
      it "does not create another subscriber" do
        expect { create_subscription }.not_to change(Subscriber, :count)
      end
    end

    context "without an existing subscriber" do
      let(:address) { "another@example.com" }

      it "creates a new subscriber" do
        expect { create_subscription }.to change(Subscriber, :count).by(1)
        expect(Subscriber.exists?(address:)).to be_truthy
      end
    end

    context "without an existing subscription" do
      it "returns a 200" do
        params = JSON.dump(address: "test@example.com", subscriber_list_id: subscriber_list.id)
        post "/subscriptions", params: params, headers: json_headers

        expect(response.status).to eq(200)
      end

      it "creates the subscription" do
        expect { create_subscription }.to change(Subscription, :count).by(1)
        expect(Subscription.first.subscriber_list).to eq(subscriber_list)
      end

      it "returns the new subscription" do
        create_subscription
        expect(data[:subscription][:id]).to_not be_nil
        expect(data[:subscription][:frequency]).to eq frequency
      end

      it "sends a confirmation email" do
        stub_notify
        create_subscription
        expect(a_request(:post, /notifications/)).to have_been_made.at_least_once
      end
    end

    context "with an invalid email address" do
      let(:subscriber_list) { create(:subscriber_list) }

      it "cannot process the request" do
        post "/subscriptions", params: { subscriber_list_id: subscriber_list.id, address: "invalid" }
        expect(response.status).to eq(422)
      end
    end
  end

  context "without authentication" do
    it "returns a 401" do
      without_login do
        post "/subscriptions", params: {}, headers: {}
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      post "/subscriptions", params: {}, headers: {}
      expect(response.status).to eq(403)
    end
  end
end

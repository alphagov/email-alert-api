RSpec.describe "Subscriptions", type: :request do
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

    context "with an existing subscription" do
      let(:subscriber_list) { create(:subscriber_list) }
      let(:subscriber) { create(:subscriber, address: "test@example.com") }
      let!(:subscription) { create(:subscription, subscriber_list: subscriber_list, subscriber: subscriber, frequency: :immediately) }
      let(:frequency) { "daily" }

      def create_subscription(extra_params: {})
        params = {
          subscriber_list_id: subscriber_list.id,
          address: subscriber.address,
          frequency: frequency,
        }

        post "/subscriptions", params: params.merge(extra_params)
      end

      context "with an existing subscription with different frequency" do
        let(:frequency) { "weekly" }

        it "creates a new subscription" do
          expect { create_subscription }.to change(Subscription, :count)
        end

        it "returns status code 200" do
          create_subscription
          expect(response.status).to eq(200)
        end

        it "returns the ID of the new subscription" do
          create_subscription
          expect(data[:id]).to_not eq(subscription.id)
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
        it "does not a confirmation email" do
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
        let(:frequency) { "immediately" }

        it "does not create a new subscription" do
          expect { create_subscription }.to_not change(Subscription, :count)
        end

        it "returns status code 200" do
          create_subscription
          expect(response.status).to eq(200)
        end

        it "returns the ID of the existing subscription" do
          create_subscription
          expect(data[:id]).to eq(subscription.id)
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

      context "with an ended subscription" do
        let!(:subscription) { create(:subscription, :ended, subscriber_list: subscriber_list, subscriber: subscriber) }

        it "leaves the subscription as ended" do
          create_subscription

          expect(subscription.reload.active?).to be false
          expect(subscription.reload.ended?).to be true
        end
      end

      it "lets you query the subscription" do
        get "/subscriptions/#{subscription.id}"
        check_json_is_valid
      end

      it "lets you query for a more recent subscription" do
        get "/subscriptions/#{subscription.id}/latest"
        check_json_is_valid
      end
    end

    context "with an existing subscription and an expired matching subscription" do
      let(:subscriber_list) { create(:subscriber_list) }
      let(:subscriber) { create(:subscriber, address: "test@example.com") }
      let!(:old_subscription) { create(:subscription, :ended, subscriber_list: subscriber_list, subscriber: subscriber, created_at: 1000.days.ago) }
      let!(:new_subscription) { create(:subscription, subscriber_list: subscriber_list, subscriber: subscriber) }

      it "returns a more recent subscription if it exists" do
        get "/subscriptions/#{old_subscription.id}/latest"
        expect(response.status).to eq(200)
        expect(data[:subscription][:id]).to eq new_subscription.id
      end
    end

    context "without an existing subscription" do
      context "with a subscriber_list" do
        let(:subscriber_list) { create(:subscriber_list) }

        def create_subscription
          post "/subscriptions", params: { subscriber_list_id: subscriber_list.id, address: "test@example.com" }
        end

        context "with an existing subscriber" do
          before do
            create(:subscriber, address: "test@example.com")
          end

          it "does not create another subscriber" do
            expect { create_subscription }.not_to change(Subscriber, :count)
          end
        end

        context "without an existing subscriber" do
          it "creates a new subscriber" do
            expect { create_subscription }.to change(Subscriber, :count).by(1)
            expect(Subscriber.first.address).to eq("test@example.com")
          end
        end

        it "creates the subscription" do
          expect { create_subscription }.to change(Subscription, :count).by(1)
          expect(Subscription.first.subscriber_list).to eq(subscriber_list)
        end

        it "returns the ID of the new subscription" do
          create_subscription
          expect(response.media_type).to eq("application/json")
          expect(data[:id]).not_to be_nil
        end
      end

      it "raises a 404 querying a non-existing subscription" do
        get "/subscriptions/3c926708-ecfa-4165-889d-c0d45cbdc01c"
        expect(response.status).to eq(404)
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
        post "/subscriptions", params: { subscriber_list_id: 10, address: "test@example.com" }
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      post "/subscriptions", params: { subscriber_list_id: 10, address: "test@example.com" }
      expect(response.status).to eq(403)
    end
  end
end

def check_json_is_valid
  expect(response.status).to eq(200)
  expect(data[:subscription].keys).to match_array(%i[
    id
    subscriber_list
    subscriber
    created_at
    updated_at
    ended_at
    ended_reason
    ended_email_id
    frequency
    source
  ])
end

RSpec.describe "Subscriptions", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    it "requires an address parameter" do
      post "/subscriptions", params: { subscribable_id: 10 }
      expect(response.status).to eq(400)
    end

    it "requires a subscribable_id parameter" do
      post "/subscriptions", params: { address: "test@example.com" }
      expect(response.status).to eq(400)
    end

    it "fails with an invalid subscribable" do
      post "/subscriptions", params: { subscribable_id: 10, address: "test@example.com" }
      expect(response.status).to eq(404)
    end

    context "with an existing subscription" do
      let(:subscribable) { create(:subscriber_list) }
      let(:subscriber) { create(:subscriber, address: "test@example.com") }
      let!(:subscription) { create(:subscription, subscriber_list: subscribable, subscriber: subscriber) }

      def create_subscription
        post "/subscriptions", params: { subscribable_id: subscribable.id, address: subscriber.address }
      end

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

      context "with an ended subscription" do
        let!(:subscription) { create(:subscription, :ended, subscriber_list: subscribable, subscriber: subscriber) }

        it "leaves the subscription as ended" do
          create_subscription

          expect(subscription.reload.active?).to be false
          expect(subscription.reload.ended?).to be true
        end
      end

      it "lets you query the subscription" do
        get "/subscriptions/#{subscription.id}"
        expect(response.status).to eq(200)
        expect(data[:subscription].keys).to match_array(%i(
          id
          subscriber_list
          subscriber
          created_at
          updated_at
          ended_at
          ended_reason
          frequency
          source
        ))
      end
    end

    context "without an existing subscription" do
      context "with a subscribable" do
        let(:subscribable) { create(:subscriber_list) }

        def create_subscription
          post "/subscriptions", params: { subscribable_id: subscribable.id, address: "test@example.com" }
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
          expect(Subscription.first.subscriber_list).to eq(subscribable)
        end

        it "returns status code 201" do
          create_subscription
          expect(response.status).to eq(201)
        end

        it "returns JSON" do
          create_subscription
          expect(response.content_type).to eq("application/json")
        end

        it "returns the ID of the new subscription" do
          create_subscription
          expect(data[:id]).not_to be_nil
        end
      end

      context "when changing a subscription's frequency" do
        context "with an existing subscription" do
          let!(:subscription) { create(:subscription, frequency: "immediately") }

          it "changes the frequency if the new frequency is valid" do
            patch "/subscriptions/#{subscription.id}", params: { frequency: "weekly" }
            expect(response.status).to eq(200)
            expect(data[:subscription][:frequency]).to eq("weekly")
          end

          it "returns an error message if the new frequency is invalid" do
            patch "/subscriptions/#{subscription.id}", params: { frequency: "monthly" }
            expect(response.status).to eq(422)
          end
        end

        context "without an existing subscription" do
          it "returns a 404" do
            patch "/subscriptions/xxxx", params: { frequency: "daily" }
            expect(response.status).to eq(404)
          end
        end
      end

      it "raises a 404 querying a non-existing subscription" do
        get "/subscriptions/3c926708-ecfa-4165-889d-c0d45cbdc01c"
        expect(response.status).to eq(404)
      end
    end

    context "with an invalid email address" do
      let(:subscribable) { create(:subscriber_list) }

      it "cannot process the request" do
        post "/subscriptions", params: { subscribable_id: subscribable.id, address: "invalid" }
        expect(response.status).to eq(422)
      end
    end
  end

  context "without authentication" do
    it "returns a 401" do
      without_login do
        post "/subscriptions", params: { subscribable_id: 10, address: "test@example.com" }
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      post "/subscriptions", params: { subscribable_id: 10, address: "test@example.com" }
      expect(response.status).to eq(403)
    end
  end
end

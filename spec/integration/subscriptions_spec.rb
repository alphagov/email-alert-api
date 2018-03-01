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

      it "doesn't create a new subscription" do
        expect { create_subscription }.not_to change(Subscription, :count)
      end

      it "returns status code 201" do
        create_subscription
        expect(response.status).to eq(200)
      end

      it "returns the ID of the existing subscription" do
        create_subscription
        expect(data[:id]).to eq(subscription.id)
      end

      context "with a deleted subscription" do
        let!(:subscription) { create(:subscription, subscriber_list: subscribable, subscriber: subscriber, ended_at: 1.day.ago) }

        it "undeletes the subscription" do
          create_subscription
          expect(Subscription.find(subscription.id).ended_at).to be_nil
        end
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
    it "returns a 403" do
      post "/subscriptions", params: { subscribable_id: 10, address: "test@example.com" }
      expect(response.status).to eq(403)
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

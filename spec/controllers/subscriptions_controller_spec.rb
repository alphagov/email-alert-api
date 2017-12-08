RSpec.describe SubscriptionsController, type: :controller do
  let(:data) { JSON.parse(response.body).deep_symbolize_keys }

  it "requires an address parameter" do
    expect {
      post :create, params: { subscribable_id: 10 }
    }.to raise_error(ActionController::ParameterMissing)
  end

  it "requires a subscribable_id parameter" do
    expect {
      post :create, params: { address: "test@example.com" }
    }.to raise_error(ActionController::ParameterMissing)
  end

  it "fails with an invalid subscribable" do
    expect {
      post :create, params: { subscribable_id: 10, address: "test@example.com" }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context "with an existing subscription" do
    let(:subscribable) { create(:subscriber_list) }
    let(:subscriber) { create(:subscriber, address: "test@example.com") }
    let!(:subscription) { create(:subscription, subscriber_list: subscribable, subscriber: subscriber) }

    def create_subscription
      post :create, params: { subscribable_id: subscribable.id, address: subscriber.address }, format: :json
    end

    it "doesn't create a new subscription" do
      expect { create_subscription }.to_not(change { Subscription.count })
    end

    it "returns status code 201" do
      create_subscription
      expect(response.status).to eq(200)
    end

    it "returns the ID of the existing subscription" do
      create_subscription
      expect(data[:id]).to eq(subscription.id)
    end
  end

  context "without an existing subscription" do
    context "with a subscribable" do
      let(:subscribable) { create(:subscriber_list) }

      def create_subscription
        post :create, params: { subscribable_id: subscribable.id, address: "test@example.com" }, format: :json
      end

      context "with an existing subscriber" do
        before do
          create(:subscriber, address: "test@example.com")
        end

        it "does not create another subscriber" do
          expect { create_subscription }.to_not(change { Subscriber.count })
        end
      end

      context "without an existing subscriber" do
        it "creates a new subscriber" do
          expect { create_subscription }.to change { Subscriber.count }.by(1)
          expect(Subscriber.first.address).to eq("test@example.com")
        end
      end

      it "creates the subscription" do
        expect { create_subscription }.to change { Subscription.count }.by(1)
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
        expect(data[:id]).to_not be_nil
      end
    end
  end

  context "with an invalid email address" do
    let(:subscribable) { create(:subscriber_list) }

    def create_subscription
      post :create, params: { subscribable_id: subscribable.id, address: "invalid" }, format: :json
    end

    it "raises an error" do
      expect { create_subscription }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end

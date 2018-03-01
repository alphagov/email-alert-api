RSpec.describe "Creating a subscription", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    context "with a subscribable" do
      let(:subscribable) { create(:subscriber_list) }

      it "returns a 201" do
        params = JSON.dump(address: "test@example.com", subscribable_id: subscribable.id)
        post "/subscriptions", params: params, headers: JSON_HEADERS

        expect(response.status).to eq(201)
      end

      context "with a frequency setting" do
        it "returns a 201 and sets the frequency" do
          params = JSON.dump(address: "test@example.com", subscribable_id: subscribable.id, frequency: "daily")
          post "/subscriptions", params: params, headers: JSON_HEADERS

          expect(response.status).to eq(201)

          expect(Subscription.first.daily?).to be_truthy
        end

        context "with an existing subscription" do
          it "updates the frequency" do
            params = JSON.dump(address: "test@example.com", subscribable_id: subscribable.id, frequency: "daily")
            post "/subscriptions", params: params, headers: JSON_HEADERS

            expect(response.status).to eq(201)

            params = JSON.dump(address: "test@example.com", subscribable_id: subscribable.id, frequency: "weekly")
            post "/subscriptions", params: params, headers: JSON_HEADERS

            expect(response.status).to eq(200)

            expect(Subscription.first.weekly?).to be_truthy
          end
        end

        context "with a notify email address" do
          it "returns a 201 but doesn't create a subscriber or subscription" do
            params = JSON.dump(address: "simulate-delivered@notifications.service.gov.uk", subscribable_id: subscribable.id, frequency: "daily")
            expect { post "/subscriptions", params: params, headers: JSON_HEADERS }.to_not change(Subscriber, :count)

            expect(response.status).to eq(201)
          end
        end

        context "with a deactivated subscriber" do
          before do
            create(:subscriber, :deactivated, address: "deactivated@example.com")
          end

          it "activates the subscriber" do
            params = JSON.dump(address: "deactivated@example.com", subscribable_id: subscribable.id)
            post "/subscriptions", params: params, headers: JSON_HEADERS

            expect(Subscriber.first.deactivated?).to be false
            expect(Subscriber.first.activated?).to be true
          end
        end
      end
    end
  end

  context "without authentication" do
    it "returns a 403" do
      post "/subscriptions", params: {}, headers: {}
      expect(response.status).to eq(403)
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

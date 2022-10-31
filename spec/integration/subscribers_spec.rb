RSpec.describe "Subscriptions", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    context "when listing subscriptions for a subscriber" do
      context "with an existing subscriber" do
        let!(:subscriber) { create(:subscriber) }
        let!(:subscriber_list_1) { create(:subscriber_list, title: "Zebra") }
        let!(:subscriber_list_2) { create(:subscriber_list) }
        let!(:subscriber_list_3) { create(:subscriber_list, title: "Ant") }
        let!(:subscription_1) do
          create(
            :subscription,
            subscriber:,
            subscriber_list: subscriber_list_1,
            created_at: Time.zone.now.days_ago(2),
          )
        end
        let!(:subscription_2) do
          create(
            :subscription,
            subscriber:,
            subscriber_list: subscriber_list_2,
            ended_at: Time.zone.now,
            ended_reason: :frequency_changed,
          )
        end
        let!(:subscription_3) do
          create(
            :subscription,
            subscriber:,
            subscriber_list: subscriber_list_3,
            created_at: Time.zone.now.days_ago(1),
            frequency: :daily,
          )
        end

        it "lists all active subscriptions" do
          get "/subscribers/#{subscriber.id}/subscriptions"
          expect(data[:subscriptions].length).to eq(2)
        end

        it "does not list any ended subscriptions" do
          get "/subscribers/#{subscriber.id}/subscriptions"
          ended_subscription = data[:subscriptions].detect { |s| s[:id] == subscription_2.id }
          expect(ended_subscription).to be_nil
        end

        it "defaults to sorting subscriptions by created_at in descending order" do
          get "/subscribers/#{subscriber.id}/subscriptions"
          expect(data[:subscriptions].map { |s| s[:id] }).to eq([subscription_3.id, subscription_1.id])
        end

        it "orders subscriptions by parameter when valid" do
          get "/subscribers/#{subscriber.id}/subscriptions?order=title"
          expect(data[:subscriptions].map { |s| s[:subscriber_list][:title] }).to eq(%w[Ant Zebra])
        end

        it "returns unprocessable entity status if order param is invalid" do
          get "/subscribers/#{subscriber.id}/subscriptions?order=blah-blah"
          expect(response.status).to eq(422)
        end
      end

      context "without an existing subscriber" do
        it "returns status code 404" do
          get "/subscribers/x12345/subscriptions"
          expect(response.status).to eq(404)
        end
      end
    end

    context "when changing a subscriber's email address" do
      context "with an existing subscriber" do
        let!(:subscriber) { create(:subscriber) }

        it "changes the email address if the new email address is valid" do
          patch "/subscribers/#{subscriber.id}", params: { new_address: "new-test@example.com" }
          expect(response.status).to eq(200)
          expect(data[:subscriber][:address]).to eq("new-test@example.com")
        end

        it "returns an error message if the new email address is invalid" do
          patch "/subscribers/#{subscriber.id}", params: { new_address: "invalid" }
          expect(response.status).to eq(422)
        end

        it "returns an error message if the new email address is not unique" do
          create :subscriber, address: "new-test@example.com"
          patch "/subscribers/#{subscriber.id}", params: { new_address: "new-test@example.com" }
          expect(response.status).to eq(422)
        end

        context "when on_conflict=merge" do
          it "changes the email address if the new email address is valid" do
            patch "/subscribers/#{subscriber.id}", params: { new_address: "new-test@example.com", on_conflict: "merge" }
            expect(response.status).to eq(200)
            expect(data[:subscriber][:address]).to eq("new-test@example.com")
          end

          it "merges the subscribers if the new email address is not unique" do
            clashing_subscriber = create :subscriber, address: "new-test@example.com"
            patch "/subscribers/#{subscriber.id}", params: { new_address: "new-test@example.com", on_conflict: "merge" }
            expect(response.status).to eq(200)
            expect(clashing_subscriber.reload.address).to be_nil
          end
        end
      end

      context "without an existing subscriber" do
        it "returns a 404" do
          patch "/subscribers/x12345", params: { new_address: "new-doesnotexist@example.com" }
          expect(response.status).to eq(404)
        end
      end
    end

    context "when unsubscribing a subscriber from everything" do
      context "when the subscriber exists" do
        let!(:subscriber) { create(:subscriber) }
        let(:subscription) { create(:subscription, subscriber:) }

        before do
          delete "/subscribers/#{subscriber.id}"
        end

        it "deletes the subscription" do
          expect(Subscription.active.count).to eq(0)
        end

        it "responds with a 204 status" do
          expect(response.status).to eq(204)
        end
      end

      context "when the subscriber doesn't exist" do
        before do
          delete "/subscribers/123"
        end

        it "responds with a 404 status" do
          expect(response.status).to eq(404)
        end
      end
    end
  end

  context "without authentication" do
    it "returns a 401" do
      without_login do
        get "/subscribers/1/subscriptions"
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      get "/subscribers/1/subscriptions"
      expect(response.status).to eq(403)
    end
  end
end

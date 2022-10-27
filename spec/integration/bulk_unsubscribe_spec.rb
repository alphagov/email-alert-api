RSpec.describe "Destroying a subscriber list", type: :request do
  let!(:subscriber_list) { create(:subscriber_list) }

  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    it "requires a valid subscriber list" do
      post "/subscriber-lists/not-the-real-slug/bulk-unsubscribe", headers: json_headers
      expect(response.status).to eq(404)
    end

    it "returns a 202" do
      post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", headers: json_headers
      expect(response.status).to eq(202)
    end

    context "when there is a subscriber" do
      before do
        post "/subscriptions", params: { subscriber_list_id: subscriber_list.id, address: subscriber.address, frequency: "immediately" }.to_json, headers: json_headers
      end

      let!(:subscriber) { create(:subscriber) }

      it "unsubscribes them" do
        post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", headers: json_headers
        expect(subscriber.active_subscriptions.count).to eq(0)
      end

      it "does not send an email" do
        expect { post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", headers: json_headers }.not_to change(Email, :count)
      end
    end

    context "when message parameters are given" do
      let(:sender_message_id) { Digest::UUID.uuid_v5(content_id, public_updated_at) }
      let(:content_id) { SecureRandom.uuid }
      let(:public_updated_at) { "2022-01-13" }
      let(:message_params) { { body: "it's gone!", sender_message_id: } }

      it "creates a message to send" do
        expect { post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", params: message_params.to_json, headers: json_headers }.to change(Message, :count)

        message = Message.order(:created_at).last
        expect(message&.criteria_rules).to eq([{ id: subscriber_list.id }])
        expect(message&.body).to eq(message_params[:body])
      end

      context "when there is a subscriber" do
        before do
          post "/subscriptions", params: { subscriber_list_id: subscriber_list.id, address: subscriber.address, frequency: }.to_json, headers: json_headers
        end

        let(:frequency) { "immediately" }
        let!(:subscriber) { create(:subscriber) }

        it "unsubscribes them" do
          post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", params: message_params.to_json, headers: json_headers
          expect(subscriber.active_subscriptions.count).to eq(0)
        end

        it "sends an immediate email" do
          post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", params: message_params.to_json, headers: json_headers
          expect(Email.order(:created_at).last.body).to include(message_params[:body])
        end

        context "when the subscribtion is for batch updates" do
          let(:frequency) { "weekly" }

          it "sends an immediate email" do
            post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", params: message_params.to_json, headers: json_headers
            expect(Email.order(:created_at).last.body).to include(message_params[:body])
          end
        end
      end

      context "when no sender_message_id is given" do
        let(:sender_message_id) { nil }

        it "returns a 422" do
          expect { post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", params: message_params.to_json, headers: json_headers }.not_to change(Message, :count)
          expect(response.status).to eq(422)
        end
      end

      context "when the unsubscribe has already been requested" do
        before do
          create(:message, sender_message_id:)
        end

        it "returns a 409" do
          expect { post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", params: message_params.to_json, headers: json_headers }.not_to change(Message, :count)
          expect(response.status).to eq(409)
        end
      end
    end
  end

  context "without authentication" do
    it "returns 401" do
      without_login do
        post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", headers: json_headers
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns 403" do
      login_with_signin
      post "/subscriber-lists/#{subscriber_list.slug}/bulk-unsubscribe", headers: json_headers

      expect(response.status).to eq(403)
    end
  end
end

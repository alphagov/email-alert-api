RSpec.describe BulkUnsubscribeListService do
  describe ".call" do
    let(:params) { {} }

    let(:subscriber_list) { create(:subscriber_list) }

    let(:govuk_request_id) { SecureRandom.uuid }

    it "queues a job" do
      expect(BulkUnsubscribeListWorker).to receive(:perform_async)

      described_class.call(subscriber_list:, params:, govuk_request_id:)
    end

    it "does not create a Message" do
      expect { described_class.call(subscriber_list:, params:, govuk_request_id:) }.not_to change(Message, :count)
    end

    context "when a body is given" do
      let(:params) do
        {
          body: "Message body",
        }
      end

      it "creates a Message" do
        expect { described_class.call(subscriber_list:, params:, govuk_request_id:) }.to change(Message, :count).by(1)

        expect(Message.last).to have_attributes(
          title: subscriber_list.title,
          body: "Message body",
          criteria_rules: [{ id: subscriber_list.id }],
          omit_footer_unsubscribe_link: true,
        )
      end

      context "when a user is given" do
        let(:user) { create(:user) }

        it "stores the user" do
          described_class.call(subscriber_list:, params:, govuk_request_id:, user:)

          expect(Message.last.signon_user_uid).to eq(user.uid)
        end
      end
    end
  end
end

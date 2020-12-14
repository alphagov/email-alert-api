RSpec.describe MessageEmailBuilder do
  let(:message) { build(:message, title: "Title") }
  let(:subscriber_list) { build(:subscriber_list, title: "My List") }
  let(:subscription) { build(:subscription, subscriber_list: subscriber_list) }
  let(:subscriber) { subscription.subscriber }

  describe ".call" do
    let(:params) do
      [
        {
          address: subscriber.address,
          message: message,
          subscriptions: [subscription, "other_subscription"],
          subscriber_id: subscriber.id,
        },
      ]
    end

    subject(:email_import) { described_class.call(params) }

    let(:email) { Email.find(email_import.first) }

    before do
      allow(MessagePresenter).to receive(:call)
        .with(message)
        .and_return("presented_message\n")

      allow(PublicUrls).to receive(:unsubscribe)
        .with(subscription)
        .and_return("unsubscribe_url")

      allow(PublicUrls).to receive(:authenticate_url)
        .with(address: subscriber.address)
        .and_return("manage_url")
    end

    it "returns an email import" do
      expect(email_import.count).to eq(1)
    end

    it "sets the subject" do
      expect(email.subject).to eq("Update from GOV.UK for: Title")
    end

    it "sets the body" do
      expect(email.body).to eq(
        <<~BODY,
          Update from GOV.UK for:

          # My List

          ---

          presented_message


          ---

          # Why am I getting this email?

          You asked GOV.UK to send you an email each time we add or update a page about:

          My List

          # [Unsubscribe](unsubscribe_url)

          [Manage your email preferences](manage_url)
        BODY
      )
    end

    it "sets the subscriber id" do
      expect(email.subscriber_id).to eq(subscriber.id)
    end

    it "raises an ArgumentError when given an empty collection of parameters" do
      expect { described_class.call([]) }.to raise_error(ArgumentError)
    end

    context "with a description" do
      let(:subscriber_list) { create(:subscriber_list, description: "description") }

      it "sets the body" do
        expect(email.body).to include(
          <<~BODY,
            ---

            presented_message

            description

            ---
          BODY
        )
      end
    end
  end
end

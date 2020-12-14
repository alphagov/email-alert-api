RSpec.describe ImmediateEmailBuilder do
  describe ".call" do
    let(:subscriber_list) { build(:subscriber_list, title: "My List") }
    let(:subscription) { build(:subscription, subscriber_list: subscriber_list) }
    let(:subscriber) { subscription.subscriber }

    let(:params) do
      {
        address: subscriber.address,
        subscriptions: [subscription, "other_subscription"],
        subscriber_id: subscriber.id,
      }
    end

    before do
      allow(PublicUrls).to receive(:unsubscribe)
        .with(subscription)
        .and_return("unsubscribe_url")

      allow(PublicUrls).to receive(:authenticate_url)
        .with(address: subscriber.address)
        .and_return("manage_url")
    end

    it "raises an ArgumentError when given an empty collection of parameters" do
      expect { described_class.call([]) }.to raise_error(ArgumentError)
    end

    context "for a content change" do
      let(:content_change) { build(:content_change, title: "Title") }

      subject(:email) do
        params.merge!(content: content_change)
        import = described_class.call([params])
        Email.find(import.first)
      end

      before do
        allow(ContentChangePresenter).to receive(:call)
          .with(content_change)
          .and_return("presented_content_change\n")
      end

      it "creates an email" do
        expect(email.subject).to eq("Update from GOV.UK for: Title")
        expect(email.subscriber_id).to eq(subscriber.id)

        expect(email.body).to eq(
          <<~BODY,
            Update from GOV.UK for:

            # My List

            ---

            presented_content_change


            ---

            # Why am I getting this email?

            You asked GOV.UK to send you an email each time we add or update a page about:

            My List

            # [Unsubscribe](unsubscribe_url)

            [Manage your email preferences](manage_url)
          BODY
        )
      end
    end

    context "for a message" do
      let(:message) { build(:message, title: "Title") }

      subject(:email) do
        params.merge!(content: message)
        import = described_class.call([params])
        Email.find(import.first)
      end

      before do
        allow(MessagePresenter).to receive(:call)
          .with(message)
          .and_return("presented_message\n")
      end

      it "creates an email" do
        expect(email.subject).to eq("Update from GOV.UK for: Title")
        expect(email.subscriber_id).to eq(subscriber.id)

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
    end

    context "when the list has a description" do
      let(:subscriber_list) { create(:subscriber_list, description: "description") }
      let(:content_change) { build(:content_change, title: "Title") }

      subject(:email) do
        params.merge!(content: content_change)
        import = described_class.call([params])
        Email.find(import.first)
      end

      before do
        allow(ContentChangePresenter).to receive(:call)
          .with(content_change)
          .and_return("presented_content_change\n")
      end

      it "includes it in the body" do
        expect(email.body).to include(
          <<~BODY,
            ---

            presented_content_change

            description

            ---
          BODY
        )
      end
    end
  end
end

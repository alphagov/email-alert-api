RSpec.describe DigestEmailBuilder do
  let(:digest_run) { double(range: "daily") }
  let(:subscriber) { build(:subscriber) }
  let(:address) { subscriber.address }
  let(:subscriber_id) { subscriber.id }

  let(:digest_item) do
    double(
      subscription_id: "ABC1",
      subscriber_list_title: "Test title 1",
      subscriber_list_url: nil,
      subscriber_list_slug: nil,
      subscriber_list_description: "",
      content: [
        build(:content_change),
        build(:message),
      ],
    )
  end

  let(:email) do
    described_class.call(
      address: address,
      digest_item: digest_item,
      digest_run: digest_run,
      subscriber_id: subscriber_id,
    )
  end

  before do
    allow(PublicUrls).to receive(:unsubscribe)
      .with(subscription_id: digest_item.subscription_id, subscriber_id: subscriber_id)
      .and_return("unsubscribe_url")

    allow(PublicUrls).to receive(:authenticate_url)
      .with(address: subscriber.address)
      .and_return("manage_url")

    allow(SourceUrlPresenter).to receive(:call)
      .and_return(nil)

    expect(ContentChangePresenter).to receive(:call)
      .and_return("presented_content_change\n")

    expect(MessagePresenter).to receive(:call)
      .and_return("presented_message\n")
  end

  describe ".call" do
    context "for a daily update" do
      it "creates an Email" do
        expect(email.subscriber_id).to eq(subscriber_id)
        expect(email.subject).to eq "Daily update from GOV.UK for: Test title 1"

        expect(email.body).to eq(
          <<~BODY,
            Daily update from GOV.UK for:

            # Test title 1

            ---

            presented_content_change

            ---

            presented_message

            ---

            # Why am I getting this email?

            You asked GOV.UK to send you one email a day about:

            Test title 1

            [Unsubscribe](unsubscribe_url)

            [Manage your email preferences](manage_url)
          BODY
        )
      end
    end

    context "for a weekly update" do
      let(:digest_run) { double(range: "weekly") }

      it "creates an Email" do
        expect(email.subscriber_id).to eq(subscriber_id)
        expect(email.subject).to eq "Weekly update from GOV.UK for: Test title 1"

        expect(email.body).to include(
          <<~BODY,
            Weekly update from GOV.UK for:

            # Test title 1

            ---
          BODY
        )

        expect(email.body).to include(
          <<~BODY,
            # Why am I getting this email?

            You asked GOV.UK to send you one email a week about:

            Test title 1
          BODY
        )
      end
    end

    context "when the list has a source URL" do
      before do
        allow(SourceUrlPresenter).to receive(:call)
          .and_return("Presented URL")
      end

      it "includes it in the body" do
        expect(email.body).to include(
          <<~BODY,
            Daily update from GOV.UK for:

            # Test title 1

            Presented URL

            ---
          BODY
        )
      end
    end
  end
end

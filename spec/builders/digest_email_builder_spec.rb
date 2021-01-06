RSpec.describe DigestEmailBuilder do
  let(:subscriber_list) { create(:subscriber_list, title: "Test title 1") }
  let(:subscriber) { create(:subscriber) }
  let(:frequency) { "daily" }
  let(:content) { [build(:content_change), build(:message)] }

  let(:subscription) do
    build(
      :subscription,
      frequency: frequency,
      subscriber_list: subscriber_list,
      subscriber: subscriber,
    )
  end

  let(:email) do
    described_class.call(
      content: content,
      subscription: subscription,
    )
  end

  before do
    allow(PublicUrls).to receive(:unsubscribe)
      .with(subscription)
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
        expect(email.subscriber_id).to eq(subscriber.id)
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
      let(:frequency) { "weekly" }

      it "creates an Email" do
        expect(email.subscriber_id).to eq(subscriber.id)
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

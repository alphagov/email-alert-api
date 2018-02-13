RSpec.describe ImmediateEmailBuilder do
  let(:subscriber) { build(:subscriber, address: "test@example.com") }

  let(:subscriptions) do
    [
      build(
        :subscription,
        uuid: "bef9b608-05ba-46ce-abb7-8567f4180a25",
        subscriber: subscriber,
        subscriber_list: build(:subscriber_list, title: "First Subscription")
      ),

      build(
        :subscription,
        uuid: "69ca6fce-34f5-4ebd-943c-83bd1b2e70fb",
        subscriber: subscriber,
        subscriber_list: build(:subscriber_list, title: "Second Subscription")
      ),
    ]
  end

  let(:content_change) do
    build(
      :content_change,
      title: "Title",
      public_updated_at: Time.parse("1/1/2017"),
      description: "Description",
      change_note: "Change note",
      base_path: "/base_path",
    )
  end

  describe ".call" do
    let(:subscription_contents) do
      [{ subscriber: subscriber, content_change: content_change }]
    end

    subject(:email_import) { described_class.call(subscription_contents) }

    let(:email) { Email.find(email_import.ids.first) }

    it "returns an email import" do
      expect(email_import.ids.count).to eq(1)
    end

    it "sets the subject" do
      expect(email.subject).to eq("GOV.UK update - Title")
    end

    it "sets the body and unsubscribe links" do
      expect(ContentChangePresenter).to receive(:call)
        .and_return("presented_content_change\n")

      expect(email.body).to eq(
        <<~BODY
          presented_content_change
        BODY
      )
    end

    context "with a subscription" do
      let(:subscription_contents) do
        [{ subscription: subscriptions.first, content_change: content_change }]
      end

      it "sets the body and unsubscribe links" do
        expect(UnsubscribeLinkPresenter).to receive(:call).with(
          uuid: "bef9b608-05ba-46ce-abb7-8567f4180a25",
          title: "First Subscription"
        ).and_return("unsubscribe_link")

        expect(ContentChangePresenter).to receive(:call)
          .and_return("presented_content_change\n")

        expect(email.body).to eq(
          <<~BODY
            presented_content_change

            ---

            unsubscribe_link
          BODY
        )
      end
    end
  end
end

RSpec.describe ImmediateEmailBuilder do
  let(:subscriber) { double(:subscriber, subscriptions: subscriptions, address: "test@example.com") }

  let(:subscriptions) do
    [
      double(uuid: "1234", subscriber_list: double(title: "First Subscription")),
      double(uuid: "5678", subscriber_list: double(title: "Second Subscription")),
    ]
  end

  let(:content_change) do
    double(
      title: "Title",
      public_updated_at: Time.parse("1/1/2017"),
      description: "Description",
      change_note: "Change note",
      base_path: "/base_path",
    )
  end

  describe ".call" do
    subject(:email_import) do
      described_class.call([{ subscriber: subscriber, content_change: content_change }])
    end

    let(:email) { Email.find(email_import.ids.first) }

    it "returns an email hash" do
      expect(email_import.ids.count).to eq(1)
    end

    it "sets the subject" do
      expect(email.subject).to eq("GOV.UK Update - Title")
    end

    it "sets the body and unsubscribe links" do
      expect(UnsubscribeLinkPresenter).to receive(:call).with(
        uuid: "1234",
        title: "First Subscription"
      ).and_return("unsubscribe_link_1")

      expect(UnsubscribeLinkPresenter).to receive(:call).with(
        uuid: "5678",
        title: "Second Subscription"
      ).and_return("unsubscribe_link_2")

      expect(ContentChangePresenter).to receive(:call)
        .and_return("presented_content_change\n")

      expect(email.body).to eq(
        <<~BODY
          presented_content_change

          ---

          unsubscribe_link_1

          unsubscribe_link_2
        BODY
      )
    end
  end
end

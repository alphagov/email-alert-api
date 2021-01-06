RSpec.describe BulkSubscriberListEmailBuilder do
  describe ".call" do
    let(:subscriber) { create(:subscriber) }

    let(:subscriber_lists) do
      [create(:subscriber_list, title: "My List"), create(:subscriber_list)]
    end

    let(:email) do
      email_ids = described_class.call(
        subject: "email subject",
        body: "email body",
        subscriber_lists: subscriber_lists,
      )

      Email.find(email_ids).first
    end

    before do
      allow(BulkEmailBodyPresenter).to receive(:call)
        .with("email body", subscriber_lists.first)
        .and_return("presented body")

      allow(PublicUrls).to receive(:unsubscribe)
        .with(subscription)
        .and_return("unsubscribe_url")

      allow(PublicUrls).to receive(:authenticate_url)
        .with(address: subscriber.address)
        .and_return("manage_url")
    end

    context "with one subscription" do
      let(:subscription) do
        create(:subscription, subscriber: subscriber, subscriber_list: subscriber_lists.first)
      end

      it "creates an email" do
        expect(email.subject).to eq("email subject")

        expect(email.body).to eq <<~BODY
          presented body

          ---

          # Why am I getting this email?

          You asked GOV.UK to send you an email each time we add or update a page about:

          My List

          [Unsubscribe](unsubscribe_url)

          [Manage your email preferences](manage_url)
        BODY
      end
    end

    context "with an ended subscription" do
      let(:subscription) do
        create(:subscription, :ended, subscriber_list: subscriber_lists.first)
      end

      it "creates no emails" do
        expect(email).to be_nil
      end
    end

    context "with many subscriptions" do
      let(:subscription) do
        create(:subscription, subscriber: subscriber, subscriber_list: subscriber_lists.first, created_at: 1.hour.ago)
      end

      before do
        create(:subscription, subscriber: subscriber, subscriber_list: subscriber_lists.second, created_at: 2.days.ago)
      end

      it "should only create one email per subscriber" do
        expect(email).to be_present
        expect(Email.count).to eq(1)
      end
    end
  end
end

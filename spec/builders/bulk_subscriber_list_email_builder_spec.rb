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
        subscriber_lists:,
      )

      Email.find(email_ids).first
    end

    before do
      allow(BulkEmailBodyPresenter).to receive(:call)
        .with("email body", subscriber_lists.first)
        .and_return("presented body")

      allow(FooterPresenter).to receive(:call)
        .with(subscriber, subscription)
        .and_return("presented_footer")
    end

    context "with one subscription" do
      let(:subscription) do
        create(:subscription, subscriber:, subscriber_list: subscriber_lists.first)
      end

      it "creates an email" do
        expect(email.subject).to eq("email subject")

        expect(email.body).to eq <<~BODY
          presented body

          ---

          presented_footer
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
        create(:subscription, subscriber:, subscriber_list: subscriber_lists.first, created_at: 1.hour.ago)
      end

      before do
        create(:subscription, subscriber:, subscriber_list: subscriber_lists.second, created_at: 2.days.ago)
      end

      it "should only create one email per subscriber" do
        expect(email).to be_present
        expect(Email.count).to eq(1)
      end
    end

    context "with rejected subscribers in /config/accounts/email_addresses.txt" do
      let(:excluded_subscriber) { create(:subscriber, address: "test@example.com") }
      let(:subscription) { create(:subscription, subscriber:, subscriber_list: subscriber_lists.first) }

      before do
        create(:subscription, subscriber: excluded_subscriber, subscriber_list: subscriber_lists.first)
      end

      it "should only create emails for subscribers not in the file" do
        expect(email).to be_present
        expect(Email.count).to eq(1)
        expect(Email.first.address).not_to eq("test@example.com")
      end
    end
  end
end

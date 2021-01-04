RSpec.describe BulkSubscriberListEmailBuilder do
  describe ".call" do
    let(:subscriber) { create(:subscriber) }
    let(:subscriber_lists) { create_list(:subscriber_list, 2) }

    let(:email) do
      email_ids = described_class.call(
        subject: "email subject",
        body: "email body",
        subscriber_lists: subscriber_lists,
      )

      Email.find(email_ids).first
    end

    context "with one subscription" do
      before do
        create(:subscription, subscriber: subscriber, subscriber_list: subscriber_lists.first)
      end

      it "creates an email" do
        expect(email.subject).to eq("email subject")
        expect(email.body).to eq("email body")
      end
    end

    context "with an ended subscription" do
      before do
        create(:subscription, :ended, subscriber_list: subscriber_lists.first)
      end

      it "creates no emails" do
        expect(email).to be_nil
      end
    end

    context "with many subscriptions" do
      before do
        create(:subscription, subscriber: subscriber, subscriber_list: subscriber_lists.first)
        create(:subscription, subscriber: subscriber, subscriber_list: subscriber_lists.second)
      end

      it "should only create one email per subscriber" do
        expect(email).to be_present
        expect(Email.count).to eq(1)
      end
    end
  end
end

RSpec.describe BulkSubscriberListEmailBuilder do
  let(:email_subject) { "email subject" }
  let(:body) { "email body" }

  describe ".call" do
    subject(:email_import) do
      described_class.call(subject: email_subject, body: body, subscriber_lists: subscriber_lists)
    end

    context "with one subscriber" do
      let(:subscriber_lists) { [create(:subscription).subscriber_list] }

      it "returns an email import" do
        expect(email_import.count).to eq(1)
      end

      let(:email) { Email.find(email_import.first) }

      it "sets the subject" do
        expect(email.subject).to eq("email subject")
      end

      it "sets the body" do
        expect(email.body).to eq("email body")
      end
    end

    context "with an ended subscriptions" do
      let(:subscriber_lists) { [create(:subscription, :ended).subscriber_list] }

      it "imports no emails" do
        expect(email_import.count).to eq(0)
      end
    end

    context "with a deactivated subscriber" do
      let(:subscriber) { create(:subscriber, :deactivated) }
      let(:subscriber_lists) { [create(:subscription, subscriber: subscriber).subscriber_list] }

      it "imports no emails" do
        expect(email_import.count).to eq(0)
      end
    end

    context "with many subscribers" do
      let(:subscriber_1) { create(:subscriber) }
      let(:subscriber_2) { create(:subscriber) }
      let(:subscriber_3) { create(:subscriber) }

      let(:subscriber_lists) do
        [
          create(:subscription, subscriber: subscriber_1).subscriber_list,
          create(:subscription, subscriber: subscriber_2).subscriber_list,
          create(:subscription, subscriber: subscriber_3).subscriber_list,
          create(:subscription, subscriber: subscriber_1).subscriber_list,
          create(:subscription, subscriber: subscriber_2).subscriber_list,
        ]
      end

      it "should only create one email per subscriber" do
        expect(email_import.count).to eq(3)
      end
    end
  end
end

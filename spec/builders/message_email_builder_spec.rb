RSpec.describe MessageEmailBuilder do
  let(:subscriber) { create(:subscriber, address: "test@example.com") }

  let(:subscription_one) do
    create(:subscription,
           subscriber: subscriber,
           subscriber_list: build(:subscriber_list, title: "First Subscription"))
  end

  let(:subscriptions) do
    [
      subscription_one,
      create(:subscription,
             subscriber: subscriber,
             subscriber_list: build(:subscriber_list, title: "Second Subscription")),
    ]
  end

  let(:message) { create(:message, title: "Title", body: "Some content") }

  describe ".call" do
    let(:params) do
      [
        {
          address: subscriber.address,
          message: message,
          subscriptions: [],
          subscriber_id: subscriber.id,
        }
      ]
    end

    subject(:email_import) { described_class.call(params) }

    let(:email) { Email.find(email_import.ids.first) }

    it "returns an email import" do
      expect(email_import.ids.count).to eq(1)
    end

    it "sets the subject" do
      expect(email.subject).to eq("Update from GOV.UK – Title")
    end

    it "sets the body" do
      expect(email.body).to eq(
        <<~BODY
          Update on GOV.UK.

          ---
          Title

          Some content

        BODY
      )
    end

    it "sets the subscriber id" do
      expect(email.subscriber_id).to eq(subscriber.id)
    end

    context "with a subscription" do
      let(:params) do
        [
          {
            address: subscriber.address,
            message: message,
            subscriptions: [subscription_one],
            subscriber_id: subscriber.id,
          }
        ]
      end

      subject(:email_import) { described_class.call(params) }

      let(:email) { Email.find(email_import.ids.first) }

      it "sets the body" do
        email = Email.find(email_import.ids.first)

        expect(email.body).to eq(
          <<~BODY
            Update on GOV.UK.

            ---
            Title

            Some content

            ---
            ^You’re getting this email because you subscribed to immediate updates to ‘#{subscriptions.first.subscriber_list.title}’ on GOV.UK.

            [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/authenticate?address=test%40example.com)
          BODY
        )
      end
    end
  end
end

RSpec.describe MessageEmailBuilder do
  let(:subscriber) { create(:subscriber, address: "test@example.com") }

  let(:subscription_one) do
    create(:subscription,
           subscriber: subscriber,
           subscriber_list: build(:subscriber_list, title: "First Subscription"))
  end

  let(:subscription_two) do
    create(:subscription,
           subscriber: subscriber,
           subscriber_list: build(:subscriber_list, title: "Second Subscription", url: "/subscription", description: "subscriber_list_description"))
  end

  let(:subscriptions) do
    [
      subscription_one,
      subscription_two,
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
        },
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
        <<~BODY,
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
      let(:subscription) { nil }

      let(:params) do
        [
          {
            address: subscriber.address,
            message: message,
            subscriptions: [subscription],
            subscriber_id: subscriber.id,
          },
        ]
      end

      subject(:email_import) { described_class.call(params) }

      let(:email) { Email.find(email_import.ids.first) }

      context "without a URL" do
        let(:subscription) { subscription_one }

        it "sets the body" do
          email = Email.find(email_import.ids.first)

          expect(email.body).to eq(
            <<~BODY,
              Update on GOV.UK.

              ---
              Title

              Some content

              ---
              ^You’re getting this email because you subscribed to immediate updates to ‘#{subscriptions.first.subscriber_list.title}’ on GOV.UK.

              [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/manage/authenticate?address=test%40example.com)
            BODY
          )
        end
      end

      context "with a URL and a description" do
        let(:subscription) { subscription_two }

        it "sets the body" do
          email = Email.find(email_import.ids.first)

          expect(email.body).to eq(
            <<~BODY,
              Update on GOV.UK.

              ---
              Title

              Some content

              subscriber_list_description
              ---
              ^You’re getting this email because you subscribed to immediate updates to ‘[#{subscription.subscriber_list.title}](#{Plek.new.website_root}#{subscription.subscriber_list.url})’ on GOV.UK.

              [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/manage/authenticate?address=test%40example.com)
            BODY
          )
        end
      end
    end
  end
end

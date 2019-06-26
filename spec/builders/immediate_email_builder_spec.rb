RSpec.describe ImmediateEmailBuilder do
  let(:subscriber) { build(:subscriber, address: "test@example.com") }

  let(:subscription_one) {
    build(
      :subscription,
      id: "bef9b608-05ba-46ce-abb7-8567f4180a25",
      subscriber: subscriber,
      subscriber_list: build(:subscriber_list, title: "First Subscription")
    )
  }
  let(:subscriptions) do
    [
      subscription_one,
      build(
        :subscription,
        id: "69ca6fce-34f5-4ebd-943c-83bd1b2e70fb",
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
    let(:subscription_content) do
      double(subscription: subscription_one, content_change: content_change)
    end

    let(:params) {
      [
        {
          address: subscriber.address,
          content_change: content_change,
          subscriptions: [],
          subscriber_id: subscriber.id,
        }
      ]
    }

    subject(:email_import) { described_class.call(params) }

    let(:email) { Email.find(email_import.ids.first) }

    it "returns an email import" do
      expect(email_import.ids.count).to eq(1)
    end

    it "sets the subject" do
      expect(email.subject).to eq("Update from GOV.UK – Title")
    end

    it "sets the body and unsubscribe links" do
      expect(ContentChangePresenter).to receive(:call)
        .and_return("presented_content_change\n")

      expect(email.body).to eq(
        <<~BODY
          Update on GOV.UK.

          presented_content_change

          ---
          ^Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).

          &nbsp;

          ^Do not reply to this email. Feedback? Visit http://www.dev.gov.uk/contact
        BODY
      )
    end

    it "sets the subscriber id" do
      expect(email.subscriber_id).to eq(subscriber.id)
    end

    context "with a subscription" do
      let(:subscription_content) do
        double(subscription: subscription_one, content_change: content_change)
      end

      let(:params) {
        [
          {
            address: subscriber.address,
            content_change: content_change,
            subscriptions: [subscription_one],
            subscriber_id: subscriber.id,
          }
        ]
      }

      subject(:email_import) { described_class.call(params) }

      let(:email) { Email.find(email_import.ids.first) }

      it "sets the body" do
        expect(ContentChangePresenter).to receive(:call)
          .and_return("presented_content_change\n")

        expect(email.status).to eq "pending"

        expect(email.body).to eq(
          <<~BODY
            Update on GOV.UK.

            presented_content_change

            ---
            ^You’re getting this email because you subscribed to immediate updates to ‘#{subscriptions.first.subscriber_list.title}’ on GOV.UK.

            [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/authenticate?address=test%40example.com)

            &nbsp;

            ^Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).

            &nbsp;

            ^Do not reply to this email. Feedback? Visit http://www.dev.gov.uk/contact
          BODY
        )
      end
    end
  end
end

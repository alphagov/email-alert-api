RSpec.describe ContentChangeEmailBuilder do
  let(:subscriber) { build(:subscriber, address: "test@example.com") }

  let(:subscription_one) do
    build(
      :subscription,
      id: "bef9b608-05ba-46ce-abb7-8567f4180a25",
      subscriber: subscriber,
      subscriber_list: build(:subscriber_list, title: "First Subscription"),
    )
  end
  let(:subscription_two) do
    build(
      :subscription,
      id: "69ca6fce-34f5-4ebd-943c-83bd1b2e70fb",
      subscriber: subscriber,
      subscriber_list: build(:subscriber_list, title: "Second Subscription", url: "/subscription", description: "subscriber_list_description"),
    )
  end
  let(:subscriptions) do
    [
      subscription_one,
      subscription_two,
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
        },
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
        <<~BODY,
          Update on GOV.UK.

          ---
          presented_content_change

          ---
          Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).
        BODY
      )
    end

    it "sets the subscriber id" do
      expect(email.subscriber_id).to eq(subscriber.id)
    end

    context "with a subscription" do
      let(:params) {
        [
          {
            address: subscriber.address,
            content_change: content_change,
            subscriptions: [subscription_content.subscription],
            subscriber_id: subscriber.id,
          },
        ]
      }

      subject(:email_import) { described_class.call(params) }

      let(:email) { Email.find(email_import.ids.first) }

      context "without a URL" do
        let(:subscription_content) do
          double(subscription: subscription_one, content_change: content_change)
        end

        it "sets the body" do
          expect(ContentChangePresenter).to receive(:call)
            .and_return("presented_content_change\n")

          expect(email.status).to eq "pending"

          expect(email.body).to eq(
            <<~BODY,
              Update on GOV.UK.

              ---
              presented_content_change

              ---
              ^You’re getting this email because you subscribed to immediate updates to ‘#{subscriptions.first.subscriber_list.title}’ on GOV.UK.

              [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/manage/authenticate?address=test%40example.com)

              Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).
            BODY
          )
        end
      end

      context "with a URL and a description" do
        let(:subscription_content) do
          double(subscription: subscription_two, content_change: content_change)
        end

        it "sets the body" do
          expect(ContentChangePresenter).to receive(:call)
            .and_return("presented_content_change\n")

          expect(email.status).to eq "pending"

          expect(email.body).to eq(
            <<~BODY,
              Update on GOV.UK.

              ---
              presented_content_change

              subscriber_list_description

              ---
              ^You’re getting this email because you subscribed to immediate updates to ‘[#{subscriptions.second.subscriber_list.title}](#{Plek.new.website_root}#{subscriptions.second.subscriber_list.url})’ on GOV.UK.

              [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/manage/authenticate?address=test%40example.com)

              Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).
            BODY
          )
        end
      end
    end
  end
end

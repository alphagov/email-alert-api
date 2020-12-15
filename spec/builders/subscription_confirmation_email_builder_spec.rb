RSpec.describe SubscriptionConfirmationEmailBuilder do
  describe ".call" do
    let(:subscriber_list) { create(:subscriber_list, title: "Example") }
    let(:subscriber) { create(:subscriber) }
    let(:frequency) { "immediately" }

    let(:subscription) do
      create(
        :subscription,
        frequency: frequency,
        subscriber_list: subscriber_list,
        subscriber: subscriber,
      )
    end

    before do
      allow(PublicUrls).to receive(:unsubscribe)
        .with(subscription)
        .and_return("unsubscribe_url")

      allow(PublicUrls).to receive(:authenticate_url)
        .with(address: subscriber.address)
        .and_return("manage_url")
    end

    subject(:email) do
      described_class.call(subscription: subscription)
    end

    context "for immediate subscriptions" do
      it "creates an email" do
        expect(email.subject).to eq "You’ve subscribed to: Example"

        expect(email.body).to eq <<~BODY
          # You’ve subscribed to GOV.UK emails

          You’ll get an email from GOV.UK each time we add or update a page about:

          Example

          Thanks
          GOV.UK emails
          https://www.gov.uk/help/update-email-notifications

          [Unsubscribe](unsubscribe_url)

          [Manage your email preferences](manage_url)
        BODY
      end
    end

    context "for digest subscriptions" do
      let(:frequency) { "daily" }

      it "creates an email" do
        expect(email.body).to include <<~BODY
          # You’ve subscribed to GOV.UK emails

          You’ll get one email a day from GOV.UK about:

          Example
        BODY
      end
    end

    context "when the list has a description" do
      let(:subscriber_list) do
        create(:subscriber_list, title: "Example", description: "A description")
      end

      it "includes the description" do
        expect(email.body).to include <<~BODY
          Example

          A description

          Thanks
          GOV.UK emails
        BODY
      end
    end
  end
end

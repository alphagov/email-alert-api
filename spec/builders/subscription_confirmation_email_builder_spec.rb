RSpec.describe SubscriptionConfirmationEmailBuilder do
  describe ".call" do
    let(:subscriber_list) { create(:subscriber_list, title: "Example") }
    let(:subscription) { create(:subscription, subscriber_list: subscriber_list) }

    before do
      allow(SourceUrlPresenter).to receive(:call)
        .and_return(nil)

      allow(ManageSubscriptionsLinkPresenter)
        .to receive(:call)
        .with(subscription.subscriber.address)
        .and_return("manage_url")
    end

    subject(:email) do
      described_class.call(subscription: subscription)
    end

    context "for all subscriptions" do
      it "creates an email" do
        expect(email.subject).to eq("You’ve subscribed to Example")

        expect(email.body).to eq(
          <<~BODY,
            You’ll get an email each time there are changes to Example

            ---

            manage_url
          BODY
        )
      end
    end

    context "when the list has a URL" do
      before do
        allow(SourceUrlPresenter).to receive(:call)
          .and_return("Presented URL")
      end

      it "includes it in the body" do
        expect(email.body).to eq(
          <<~BODY,
            You’ll get an email each time there are changes to Example

            Presented URL

            ---

            manage_url
          BODY
        )
      end
    end
  end
end

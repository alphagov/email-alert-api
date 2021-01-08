RSpec.describe SubscriptionConfirmationEmailBuilder do
  describe ".call" do
    let(:frequency) { "immediately" }
    let(:subscriber_list) { build(:subscriber_list, title: "My List") }
    let(:subscription) { build(:subscription, subscriber_list: subscriber_list, frequency: frequency) }
    let(:subscriber) { subscription.subscriber }

    subject(:email) { described_class.call(subscription: subscription) }

    before do
      utm_params = {
        utm_source: subscription.subscriber_list.slug,
        utm_content: frequency,
      }

      allow(PublicUrls).to receive(:unsubscribe)
        .with(subscription, **utm_params)
        .and_return("unsubscribe_url")

      allow(PublicUrls).to receive(:manage_url)
        .with(subscriber, **utm_params)
        .and_return("manage_url")
    end

    context "for an immediate subscription" do
      it "creates an email" do
        expect(email.subject).to eq("You’ve subscribed to: My List")
        expect(email.subscriber_id).to eq(subscriber.id)

        expect(email.body).to eq(
          <<~BODY,
            # You’ve subscribed to GOV.UK emails

            #{I18n.t!('emails.confirmation.frequency.immediately')}

            My List

            Thanks
            GOV.UK emails

            [Unsubscribe](unsubscribe_url)

            [Manage your email preferences](manage_url)
          BODY
        )
      end
    end

    %w[daily weekly].each do |frequency|
      context "for a #{frequency} subscription" do
        let(:frequency) { frequency }

        it "creates an email" do
          expect(email.body).to include(
            I18n.t!("emails.confirmation.frequency.#{frequency}"),
          )
        end
      end
    end

    context "when the list has a URL" do
      before do
        allow(SourceUrlPresenter).to receive(:call)
          .and_return("Presented URL")
      end

      it "includes it in the body" do
        expect(email.body).to include(
          <<~BODY,
            My List

            Presented URL

            Thanks
          BODY
        )
      end
    end
  end
end

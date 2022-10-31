RSpec.describe SubscriptionConfirmationEmailBuilder do
  describe ".call" do
    let(:frequency) { "immediately" }
    let(:subscriber_list) { build(:subscriber_list, title: "My List") }
    let(:subscription) { build(:subscription, subscriber_list:, frequency:) }
    let(:subscriber) { subscription.subscriber }

    subject(:email) { described_class.call(subscription:) }

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

            #{I18n.t!('emails.confirmation.frequency.topic.immediately')}

            My List

            Thanks
            GOV.UK emails

            [Unsubscribe](unsubscribe_url)

            [Change your email preferences](manage_url)
          BODY
        )
      end

      context "when the subscription is to a single page" do
        let(:subscriber_list) { build(:subscriber_list, :for_single_page_subscription) }
        let(:subscription) { build(:subscription, subscriber_list:, frequency: "immediately") }

        it "includes the content for a single page email" do
          expect(email.body).to include(I18n.t!("emails.confirmation.frequency.page.immediately"))
        end

        it "makes the page title a link to the page" do
          expect(email.body).to include("[#{subscriber_list.title}](http://www.dev.gov.uk#{subscriber_list.url}?utm_medium=email&utm_campaign=govuk-notifications&utm_source=#{subscriber_list.slug}&utm_content=confirmation)")
        end
      end
    end

    %w[daily weekly].each do |frequency|
      context "for a #{frequency} subscription" do
        let(:frequency) { frequency }

        it "creates an email" do
          expect(email.body).to include(
            I18n.t!("emails.confirmation.frequency.topic.#{frequency}"),
          )
        end
      end
    end
  end
end

RSpec.describe SubscriptionAuthEmailBuilder do
  describe ".call" do
    let(:frequency) { "weekly" }

    let(:subscriber_list) do
      create(:subscriber_list, slug: "business-tax-corporation-tax", title: "My List")
    end

    subject(:email) do
      described_class.call(
        address: "test@gov.uk",
        token: "secret",
        subscriber_list:,
        frequency:,
      )
    end

    before do
      allow(PublicUrls).to receive(:url_for)
        .with(base_path: "/email/subscriptions/authenticate",
              frequency:,
              token: "secret",
              topic_id: subscriber_list.slug)
        .and_return("auth_url")
    end

    it "creates an email" do
      expect(email.subject).to eq("Confirm that you want to get emails from GOV.UK")

      expect(email.body).to eq(
        <<~BODY,
          # Click the link to confirm that you want to get emails from GOV.UK

          # [Yes, I want emails about My List](auth_url)

          This link will stop working after 7 days.

          #{I18n.t!('emails.subscription_auth.frequency.weekly')}. You can change this at any time.

          If you did not request this email, you can ignore it.

          Thanks 
          GOV.UK emails 
        BODY
      )
    end

    context "for daily subscriptions" do
      let(:frequency) { "daily" }

      it "has relevant content" do
        expect(email.body).to include(I18n.t!("emails.subscription_auth.frequency.daily"))
      end
    end

    context "for immediate subscriptions" do
      let(:frequency) { "immediately" }

      it "has relevant content" do
        expect(email.body).to include(I18n.t!("emails.subscription_auth.frequency.immediately"))
      end
    end
  end
end

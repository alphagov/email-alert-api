RSpec.describe SubscriptionAuthEmailBuilder do
  describe ".call" do
    let(:address) { "test@gov.uk" }
    let(:token) { "secret" }
    let(:frequency) { "weekly" }
    let(:subscriber_list) { create :subscriber_list, slug: "business-tax-corporation-tax" }

    subject(:call) do
      described_class.call(
        address: address,
        token: token,
        subscriber_list: subscriber_list,
        frequency: frequency,
      )
    end

    before do
      allow(PublicUrls).to receive(:url_for)
        .with(base_path: "/email/subscriptions/authenticate",
              frequency: frequency,
              token: "secret",
              topic_id: subscriber_list.slug)
        .and_return("auth_url")
    end

    it { is_expected.to be_instance_of(Email) }

    it "creates an email" do
      expect { call }.to change(Email, :count).by(1)
    end

    it "has content for weekly subscriptions" do
      email = call
      expect(email.body).to include(I18n.t!("emails.subscription_auth.frequency.weekly"))
    end

    context "for daily subscriptions" do
      let(:frequency) { "daily" }

      it "has relevant content" do
        email = call
        expect(email.body).to include(I18n.t!("emails.subscription_auth.frequency.daily"))
      end
    end

    context "for immediate subscriptions" do
      let(:frequency) { "immediately" }

      it "has relevant content" do
        email = call
        expect(email.body).to include(I18n.t!("emails.subscription_auth.frequency.immediately"))
      end
    end

    it "has a link to authenticate" do
      email = call
      expect(email.body).to include("auth_url")
    end
  end
end

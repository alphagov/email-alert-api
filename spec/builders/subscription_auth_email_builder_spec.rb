RSpec.describe SubscriptionAuthEmailBuilder do
  describe ".call" do
    let(:address) { "test@gov.uk" }
    let(:token) { "secret" }
    let(:frequency) { "weekly" }
    let(:topic_id) { "business-tax-corporation-tax" }

    subject(:call) do
      described_class.call(
        address: address,
        token: token,
        topic_id: topic_id,
        frequency: frequency,
      )
    end

    it { is_expected.to be_instance_of(Email) }

    it "creates an email" do
      expect { call }.to change(Email, :count).by(1)
    end

    it "has a link to authenticate" do
      link = "http://www.dev.gov.uk/email/subscriptions/authenticate?token=#{token}&topic_id=business-tax-corporation-tax&frequency=weekly"
      email = call
      expect(email.body).to include(link)
    end
  end
end

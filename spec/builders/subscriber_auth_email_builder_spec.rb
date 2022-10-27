RSpec.describe SubscriberAuthEmailBuilder do
  describe ".call" do
    let(:subscriber) { create(:subscriber) }

    subject(:email) do
      described_class.call(
        subscriber:,
        destination: "/destination",
        token: "secret",
      )
    end

    before do
      allow(PublicUrls).to receive(:url_for)
        .with(base_path: "/destination", token: "secret")
        .and_return("auth_url")
    end

    it "creates an email" do
      expect(email.subject).to eq("Change your GOV.UK email preferences")
      expect(email.subscriber_id).to eq(subscriber.id)

      expect(email.body).to eq(
        <<~BODY,
          # Click the link to confirm your email address

          # [Yes, I want to change my GOV.UK email preferences](auth_url)

          This link will stop working after 7 days.

          If you did not request this email, you can ignore it.

          Thanks
          GOV.UK emails
        BODY
      )
    end
  end
end

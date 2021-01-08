RSpec.describe FooterPresenter do
  describe ".call" do
    let(:subscriber) { create(:subscriber) }
    let(:subscription) { create(:subscription) }

    let(:footer) do
      described_class.call(subscriber, subscription)
    end

    before do
      allow(PublicUrls).to receive(:unsubscribe)
        .with(subscription)
        .and_return("unsubscribe_url")

      allow(PublicUrls).to receive(:authenticate_url)
        .with(address: subscriber.address)
        .and_return("manage_url")
    end

    it "returns a standard footer" do
      expected = <<~FOOTER
        # Why am I getting this email?

        #{I18n.t!('emails.footer.immediately')}

        #{subscription.subscriber_list.title}

        [Unsubscribe](unsubscribe_url)

        [Manage your email preferences](manage_url)
      FOOTER

      expect(footer).to eq(expected.strip)
    end

    %w[weekly daily].each do |frequency|
      context "for a #{frequency} subscription" do
        let(:subscription) { create(:subscription, frequency: frequency) }

        it "uses a different explanation" do
          expect(footer).to include(I18n.t!("emails.footer.#{frequency}"))
        end
      end
    end
  end
end

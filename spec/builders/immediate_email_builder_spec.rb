RSpec.describe ImmediateEmailBuilder do
  describe ".call" do
    let(:subscriber_list) { build(:subscriber_list, title: "My List") }
    let(:subscription) { build(:subscription, subscriber_list:) }
    let(:subscriber) { subscription.subscriber }
    let(:omit_footer_unsubscribe_link) { false }

    before do
      allow(FooterPresenter).to receive(:call)
        .with(subscriber, subscription, omit_unsubscribe_link: false)
        .and_return("presented_footer")
    end

    it "raises an ArgumentError when given an empty collection of parameters" do
      expect { described_class.call([]) }.to raise_error(ArgumentError)
    end

    context "for a content change" do
      let(:content_change) { build(:content_change, title: "Title") }

      subject(:email) do
        import = described_class.call(content_change, [subscription])
        Email.find(import.first)
      end

      before do
        allow(ContentChangePresenter).to receive(:call)
          .with(content_change, subscription)
          .and_return("presented_content_change")
      end

      it "creates an email" do
        expect(email.subject).to eq("Update from GOV.UK for: Title")
        expect(email.subscriber_id).to eq(subscriber.id)
        expect(email.content_id).to eq(content_change.content_id)

        expect(email.body).to eq(
          <<~BODY,
            Update from GOV.UK for:

            # My List

            ---

            presented_content_change

            ---

            presented_footer
          BODY
        )
      end
    end

    context "for a message" do
      let(:message) { build(:message, title: "Title") }

      subject(:email) do
        import = described_class.call(message, [subscription])
        Email.find(import.first)
      end

      before do
        allow(MessagePresenter).to receive(:call)
          .with(message, subscription)
          .and_return("presented_message")
      end

      it "creates an email" do
        expect(email.subject).to eq("Update from GOV.UK for: Title")
        expect(email.subscriber_id).to eq(subscriber.id)
        expect(email.content_id).to be nil

        expect(email.body).to eq(
          <<~BODY,
            Update from GOV.UK for:

            # My List

            ---

            presented_message

            ---

            presented_footer
          BODY
        )
      end

      context "when the message omits the footer unsubscribe link" do
        let(:message) { build(:message, title: "Title", omit_footer_unsubscribe_link: true) }

        before do
          allow(FooterPresenter).to receive(:call)
            .with(subscriber, subscription, omit_unsubscribe_link: true)
            .and_return("presented_footer_without_unsubscribe_link")
        end

        it "creates an email without the footer unsubscribe link" do
          expect(email.subject).to eq("Update from GOV.UK for: Title")
          expect(email.subscriber_id).to eq(subscriber.id)

          expect(email.body).to eq(
            <<~BODY,
              Update from GOV.UK for:

              # My List

              ---

              presented_message

              ---

              presented_footer_without_unsubscribe_link
            BODY
          )
        end
      end
    end
  end
end

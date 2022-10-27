RSpec.describe DigestEmailBuilder do
  let(:subscriber_list) { create(:subscriber_list, title: "Test title 1") }
  let(:subscriber) { create(:subscriber) }
  let(:frequency) { "daily" }
  let(:content) { [build(:content_change), build(:message)] }

  let(:subscription) do
    build(
      :subscription,
      frequency:,
      subscriber_list:,
      subscriber:,
    )
  end

  let(:email) do
    described_class.call(
      content:,
      subscription:,
    )
  end

  before do
    allow(FooterPresenter).to receive(:call)
      .with(subscriber, subscription)
      .and_return("presented_footer")

    expect(ContentChangePresenter).to receive(:call)
      .and_return("presented_content_change")

    expect(MessagePresenter).to receive(:call)
      .and_return("presented_message")
  end

  describe ".call" do
    context "for a daily update" do
      it "creates an Email" do
        expect(email.subscriber_id).to eq(subscriber.id)
        expect(email.subject).to eq "Daily update from GOV.UK for: Test title 1"

        expect(email.body).to eq(
          <<~BODY,
            Daily update from GOV.UK for:

            # Test title 1

            ---

            presented_content_change

            ---

            presented_message

            ---

            presented_footer
          BODY
        )
      end
    end

    context "for a weekly update" do
      let(:frequency) { "weekly" }

      it "creates an Email" do
        expect(email.subscriber_id).to eq(subscriber.id)
        expect(email.subject).to eq "Weekly update from GOV.UK for: Test title 1"

        expect(email.body).to include(
          <<~BODY,
            Weekly update from GOV.UK for:

            # Test title 1

            ---
          BODY
        )
      end
    end
  end
end

RSpec.describe DigestEmailBuilder do
  let(:digest_run) { double(range: "daily") }
  let(:subscriber) { build(:subscriber) }
  let(:address) { subscriber.address }
  let(:subscriber_id) { subscriber.id }
  let(:subscription_content) {
    [
      double(
        subscription_id: "ABC1",
        subscriber_list_title: "Test title 1",
        content: [
          build(:content_change),
          build(:message),
        ],
      ),
      double(
        subscription_id: "ABC2",
        subscriber_list_title: "Test title 2",
        content: [
          build(:message),
          build(:content_change),
        ],
      ),
    ]
  }

  let(:email) {
    described_class.call(
      address: address,
      subscription_content: subscription_content,
      digest_run: digest_run,
      subscriber_id: subscriber_id
    )
  }

  it "returns an Email" do
    expect(email).to be_a(Email)
  end

  it "sets the subscriber id on the email" do
    expect(email.subscriber_id).to eq(subscriber_id)
  end

  it "adds an entry to body for each content change" do
    expect(UnsubscribeLinkPresenter).to receive(:call).with(
      id: "ABC1",
      title: "Test title 1"
    ).and_return("unsubscribe_link_1")

    expect(UnsubscribeLinkPresenter).to receive(:call).with(
      id: "ABC2",
      title: "Test title 2"
    ).and_return("unsubscribe_link_2")

    expect(ContentChangePresenter).to receive(:call).exactly(2).times
      .and_return("presented_content_change\n")

    expect(MessagePresenter).to receive(:call).exactly(2).times
      .and_return("presented_message\n")

    expect(email.body).to eq(
      <<~BODY
        Daily update from GOV.UK.

        #Test title 1&nbsp;

        presented_content_change

        ---

        presented_message

        ---

        unsubscribe_link_1

        &nbsp;

        #Test title 2&nbsp;

        presented_message

        ---

        presented_content_change

        ---

        unsubscribe_link_2

        ^You’re getting this email because you subscribed to daily updates on these topics on GOV.UK.

        [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/authenticate?address=#{ERB::Util.url_encode(subscriber.address)})

        Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=digests).
      BODY
    )
  end

  it "saves the email" do
    expect(email.id).to_not be_nil
    expect(Email.count).to eq(1)
  end

  context "daily" do
    it "sets the subject" do
      expect(email.subject).to eq("Daily update from GOV.UK")
    end
  end

  context "weekly" do
    let(:digest_run) { double(range: "weekly") }
    it "sets the subject" do
      expect(email.subject).to eq("Weekly update from GOV.UK")
    end
  end
end

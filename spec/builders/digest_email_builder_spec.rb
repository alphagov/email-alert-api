RSpec.describe DigestEmailBuilder do
  let(:digest_run) { double(range: "daily") }
  let(:subscriber) { build(:subscriber) }
  let(:address) { subscriber.address }
  let(:subscriber_id) { subscriber.id }
  let(:digest_items) do
    [
      double(
        subscription_id: "ABC1",
        subscriber_list_title: "Test title 1",
        subscriber_list_url: nil,
        subscriber_list_description: "",
        content: [
          build(:content_change),
          build(:message),
        ],
      ),
      double(
        subscription_id: "ABC2",
        subscriber_list_title: "Test title 2",
        subscriber_list_url: "/test-title-2",
        subscriber_list_description: "Test description",
        content: [
          build(:message),
          build(:content_change),
        ],
      ),
    ]
  end

  let(:email) do
    described_class.call(
      address: address,
      digest_items: digest_items,
      digest_run: digest_run,
      subscriber_id: subscriber_id,
    )
  end

  before do
    allow(SourceUrlPresenter).to receive(:call)
      .and_return(nil)

    allow(SourceUrlPresenter).to receive(:call)
      .with("/test-title-2")
      .and_return("Presented URL")
  end

  it "returns an Email" do
    expect(email).to be_a(Email)
  end

  it "sets the subscriber id on the email" do
    expect(email.subscriber_id).to eq(subscriber_id)
  end

  it "adds an entry to body for each content change" do
    expect(UnsubscribeLinkPresenter)
      .to receive(:call).with("ABC1", "Test title 1")
      .and_return("unsubscribe_link_1")

    expect(UnsubscribeLinkPresenter)
      .to receive(:call).with("ABC2", "Test title 2")
      .and_return("unsubscribe_link_2")

    expect(ContentChangePresenter).to receive(:call).exactly(2).times
      .and_return("presented_content_change\n")

    expect(MessagePresenter).to receive(:call).exactly(2).times
      .and_return("presented_message\n")

    expect(email.body).to eq(
      <<~BODY,
        Daily update from GOV.UK.

        # Test title 1 &nbsp;

        presented_content_change

        ---

        presented_message

        ---

        unsubscribe_link_1

        &nbsp;

        # [Test title 2](http://www.dev.gov.uk/test-title-2) &nbsp;

        Presented URL

        presented_message

        ---

        presented_content_change

        ---

        unsubscribe_link_2

        ^You’re getting this email because you subscribed to daily updates on these topics on GOV.UK.

        [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/manage/authenticate?address=#{ERB::Util.url_encode(subscriber.address)})
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

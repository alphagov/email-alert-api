RSpec.describe DigestEmailBuilder do
  let(:digest_run) { double(range: "daily") }
  let(:subscriber) { build(:subscriber) }
  let(:address) { subscriber.address }
  let(:subscriber_id) { subscriber.id }
  let(:subscription_content_changes) {
    [
      double(
        subscription_id: "ABC1",
        subscriber_list_title: "Test title 1",
        content_changes: [
          build(:content_change, public_updated_at: "1/1/2016 10:00"),
          build(:content_change, public_updated_at: "2/1/2016 11:00"),
          build(:content_change, public_updated_at: "3/1/2016 12:00"),
        ],
      ),
      double(
        subscription_id: "ABC2",
        subscriber_list_title: "Test title 2",
        content_changes: [
          build(:content_change, public_updated_at: "4/1/2016 10:00"),
          build(:content_change, public_updated_at: "5/1/2016 11:00"),
          build(:content_change, public_updated_at: "6/1/2016 12:00"),
        ],
      ),
    ]
  }

  let(:email) {
    described_class.call(
      address: address,
      subscription_content_changes: subscription_content_changes,
      digest_run: digest_run,
      subscriber_id: subscriber_id
    )
  }

  def simulated_deduplification(content_changes)
    content_changes.slice(0, content_changes.length - 1)
  end

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

    first_content_changes = subscription_content_changes
      .first
      .content_changes

    second_content_changes = subscription_content_changes
      .second
      .content_changes

    expect(ContentChangeDeduplicatorService).to receive(:call)
      .with(first_content_changes)
      .and_return(simulated_deduplification(first_content_changes))

    expect(ContentChangeDeduplicatorService).to receive(:call)
      .with(second_content_changes)
      .and_return(simulated_deduplification(second_content_changes))

    expect(ContentChangePresenter).to receive(:call).exactly(4).times
      .and_return("presented_content_change\n")

    expect(email.body).to eq(
      <<~BODY
        Daily update from GOV.UK.

        #Test title 1&nbsp;

        presented_content_change

        ---

        presented_content_change

        ---

        unsubscribe_link_1

        &nbsp;

        #Test title 2&nbsp;

        presented_content_change

        ---

        presented_content_change

        ---

        unsubscribe_link_2


        &nbsp;

        ---

        You’re getting this email because you subscribed to GOV.UK email alerts.
        [View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/authenticate?address=#{ERB::Util.url_encode(subscriber.address)})

        &nbsp;

        ^Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=digests).

        &nbsp;

        ^Do not reply to this email. Feedback? Visit http://www.dev.gov.uk/contact
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

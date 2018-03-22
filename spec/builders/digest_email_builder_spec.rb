require "rails_helper"
RSpec.describe DigestEmailBuilder do
  let(:digest_run) { double(daily?: true) }
  let(:subscriber) { build(:subscriber) }
  let(:subscription_content_change_results) {
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
      subscriber: subscriber,
      digest_run: digest_run,
      subscription_content_change_results: subscription_content_change_results,
    )
  }

  def simulated_deduplification(content_changes)
    content_changes.slice(0, content_changes.length - 1)
  end

  it "returns an Email" do
    expect(email).to be_a(Email)
  end

  it "sets the subscriber id on the email" do
    expect(email.subscriber_id).to eq(subscriber.id)
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

    first_content_changes = subscription_content_change_results
      .first
      .content_changes

    second_content_changes = subscription_content_change_results
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

        You’re getting this email because you subscribed to these topic updates on GOV.UK.
        [View and manage your subscriptions](/magic-manage-link)

        \u00A0

        ^Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=digests).
      BODY
    )
  end

  it "saves the email" do
    expect(email.id).to_not be_nil
    expect(Email.count).to eq(1)
  end

  context "daily" do
    it "sets the subject" do
      expect(email.subject).to eq("GOV.UK: your daily update")
    end
  end

  context "weekly" do
    let(:digest_run) { double(daily?: false) }
    it "sets the subject" do
      expect(email.subject).to eq("GOV.UK: your weekly update")
    end
  end
end

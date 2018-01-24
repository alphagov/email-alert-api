RSpec.describe ImmediateEmailBuilder do
  let(:subscriber) { double(:subscriber, subscriptions: subscriptions) }

  let(:subscriptions) do
    [
      double(uuid: "1234", subscriber_list: double(title: "First Subscription")),
      double(uuid: "5678", subscriber_list: double(title: "Second Subscription")),
    ]
  end

  let(:params) do
    {
      title: "Title",
      public_updated_at: Time.parse("1/1/2017"),
      description: "Description",
      change_note: "Change note",
      base_path: "/base_path",
      subscriber: subscriber,
    }
  end

  subject { described_class.new(params: params) }

  describe "subject" do
    it "should match the expected title" do
      expect(subject.subject).to eq("GOV.UK Update - #{params[:title]}")
    end
  end

  describe "body" do
    it "should match the expected content" do
      expect(subject.body).to eq(
        <<~BODY
          [Title](http://www.dev.gov.uk/base_path)

          Change note: Description.

          Updated at 12:00 am on 1 January 2017

          ----

          Unsubscribe from [First Subscription](http://www.dev.gov.uk/email/unsubscribe/1234?title=First%20Subscription)

          Unsubscribe from [Second Subscription](http://www.dev.gov.uk/email/unsubscribe/5678?title=Second%20Subscription)
        BODY
      )
    end
  end
end

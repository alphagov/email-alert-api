RSpec.describe EmailRenderer do
  let(:subscriber) { double(:subscriber, subscriptions: subscriptions) }

  before do
    create(:subscription, uuid: "ad22a6f8-d6dd-4989-98e0-29a7c1049173", subscriber_list: create(:subscriber_list, title: "First Subscription"))
    create(:subscription, uuid: "6fabfabd-8d02-4dc3-8190-a647ae69aef2", subscriber_list: create(:subscriber_list, title: "Second Subscription"))
  end

  let(:subscriptions) { Subscription.all }

  let(:params) do
    {
      title: "Title",
      public_updated_at: DateTime.parse("1/1/2017"),
      description: "Description",
      change_note: "Change note",
      base_path: "/base_path",
      subscriber: subscriber,
    }
  end

  subject { EmailRenderer.new(params: params) }

  describe "subject" do
    it "should match the expected title" do
      expect(subject.subject).to eq("GOV.UK Update - #{params[:title]}")
    end
  end

  describe "body" do
    it "should match the expected content" do
      expect(subject.body).to eq(
        <<~BODY
          Change note: Description.

          http://www.dev.gov.uk/base_path
          Updated on 12:00 am, 1 January 2017

          Unsubscribe from 'First Subscription':
          http://www.dev.gov.uk/email/unsubscribe/ad22a6f8-d6dd-4989-98e0-29a7c1049173?title=First%20Subscription

          Unsubscribe from 'Second Subscription':
          http://www.dev.gov.uk/email/unsubscribe/6fabfabd-8d02-4dc3-8190-a647ae69aef2?title=Second%20Subscription
        BODY
      )
    end
  end
end

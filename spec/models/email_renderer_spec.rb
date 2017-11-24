require 'rails_helper'

RSpec.describe EmailRenderer do
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
          http://www.dev.gov.uk/email/unsubscribe/1234?title=First%20Subscription

          Unsubscribe from 'Second Subscription':
          http://www.dev.gov.uk/email/unsubscribe/5678?title=Second%20Subscription
        BODY
      )
    end
  end
end

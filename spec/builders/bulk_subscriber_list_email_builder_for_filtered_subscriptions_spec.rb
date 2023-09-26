RSpec.describe BulkSubscriberListEmailBuilderForFilteredSubscriptions do
  describe ".call" do
    let!(:trade_marks_subscriber_list) { create(:subscriber_list, title: "Trade marks", slug: "intellectual-property-trade-marks") }

    let(:email_body) do
      <<~BODY
        You asked GOV.UK to email you when we add or update a page about Trade marks.

        We emailed you earlier to say that the Trade marks page has been archived. The email included the wrong link for where you can find out more information about the topic.

        You can find out more information about intellectual property trade marks at https://www.gov.uk/government/collections/intellectual-property-trade-marks

        You can also sign up for email updates on that page if you would like to continue to get email updates from GOV.UK about trade marks.
      BODY
    end

    let(:email_subject) { "CORRECTION - Update from GOV.UK for: Trade marks" }

    let!(:target_date) { Time.zone.local(2023, 9, 22) }
    let!(:other_date) { Time.zone.local(2021, 1, 1) }

    let!(:subscriber_one) { create(:subscriber) }
    let!(:subscriber_two) { create(:subscriber) }
    let!(:subscriber_three) { create(:subscriber) }

    let!(:subscription_bulk_unsubscribed_on_target_date) do
      create(:subscription, subscriber: subscriber_one, subscriber_list: trade_marks_subscriber_list, ended_at: target_date, ended_reason: "bulk_unsubscribed")
    end

    let!(:subscription_bulk_unsubscribed_on_other_date) do
      create(:subscription, subscriber: subscriber_two, subscriber_list: trade_marks_subscriber_list, ended_at: other_date, ended_reason: "bulk_unsubscribed")
    end

    let!(:subscription_unsubscribed_by_user_on_target_date) do
      create(:subscription, subscriber: subscriber_three, subscriber_list: trade_marks_subscriber_list, ended_at: target_date, ended_reason: "subscriber_list_changed")
    end

    it "should only create an email for the users who were bulk unsubscribed on the target date" do
      email_ids = described_class.new(trade_marks_subscriber_list).call

      expect(email_ids.count).to eq 1

      email = Email.find(email_ids).first

      expect(email.subscriber_id).to eq subscriber_one.id
      expect(email.address).to eq subscriber_one.address
      expect(email.subject).to eq email_subject
      expect(email.body).to eq email_body
    end
  end
end

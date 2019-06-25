RSpec.describe "Unsubscribing from a subscriber_list", type: :request do
  before do
    stub_notify
  end

  scenario "unsubscribing from an email uuid, then no longer receiving emails" do
    Timecop.freeze "2019-06-26 10:00" do
      login_with_internal_app

      subscriber_list_id = create_subscriber_list
      subscribe_to_subscriber_list(subscriber_list_id, frequency: "daily")

      Timecop.freeze "2019-06-25 09:30:00" do
        create_content_change(public_updated_at: "2019-06-25 10:00:00")
      end

      DailyDigestInitiatorWorker.new.perform
      Sidekiq::Worker.drain_all

      email_data = expect_an_email_was_sent

      id = extract_unsubscribe_id(email_data)
      unsubscribe_from_subscriber_list(id, expected_status: 204)

      clear_any_requests_that_have_been_recorded!

      Timecop.freeze "2019-06-25 09:30:01" do
        create_content_change(public_updated_at: "2019-06-25 10:00:00")
      end

      DailyDigestInitiatorWorker.new.perform
      Sidekiq::Worker.drain_all

      expect_an_email_was_not_sent

      unsubscribe_from_subscriber_list(id, expected_status: 404)
      unsubscribe_from_subscriber_list("missing", expected_status: 404)
    end
  end
end

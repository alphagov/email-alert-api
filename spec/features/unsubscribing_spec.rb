RSpec.describe "Unsubscribing from a subscriber_list", type: :request do
  scenario "unsubscribing from an email uuid, then no longer receiving emails" do
    login_with_internal_app
    subscriber_list = create_subscriber_list
    subscribe_to_subscriber_list(subscriber_list[:id], frequency: "daily")

    travel_to(Time.zone.yesterday.midday) { create_content_change }

    travel_to(Time.zone.today.midday) do
      DailyDigestInitiatorJob.new.perform
      Sidekiq::Job.drain_all
    end

    email_data = expect_an_email_was_sent
    id = extract_unsubscribe_id(email_data)
    unsubscribe_from_subscriber_list(id, expected_status: 204)
    clear_any_requests_that_have_been_recorded!

    travel_to(Time.zone.today.midnight) { create_content_change }

    travel_to(Time.zone.tomorrow.midday) do
      DailyDigestInitiatorJob.new.perform
      Sidekiq::Job.drain_all
    end

    expect_an_email_was_not_sent
    unsubscribe_from_subscriber_list(id, expected_status: 404)
    unsubscribe_from_subscriber_list("missing", expected_status: 404)
  end

  def unsubscribe_from_subscriber_list(id, expected_status: 204)
    post "/unsubscribe/#{id}"
    expect(response.status).to eq(expected_status)
  end

  def extract_unsubscribe_id(email_data)
    body = email_data.dig(:personalisation, :body)
    body[%r{/unsubscribe/(.*)\)}, 1]
  end
end

RSpec.describe "Delivering an email successfully via Notify", type: :request do
  before do
    stub_notify
  end

  scenario "sending an email and receiving a 'delivered' status update" do
    login_with(%w(internal_app status_updates))

    subscribable_id = create_subscribable
    subscribe_to_subscribable(subscribable_id)
    create_content_change
    email_data = expect_an_email_was_sent

    reference = email_data.fetch(:reference)
    completed_at = Time.parse("2017-05-14T12:15:30.000000Z")
    sent_at = Time.parse("2017-05-14T12:15:30.000000Z")

    send_status_update(reference, "delivered", completed_at, sent_at, expected_status: 204)
    send_status_update("missing", "delivered", completed_at, sent_at, expected_status: 404)
    send_status_update(nil,       "delivered", completed_at, sent_at, expected_status: 400)
  end
end

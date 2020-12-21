RSpec.describe "Subscribing to a subscriber_list", type: :request do
  scenario "subscribing to a subscriber_list" do
    login_with_internal_app

    subscriber_list_id = create_subscriber_list

    subscribe_to_subscriber_list(subscriber_list_id, expected_status: 200)
    expect_an_email_was_sent(subject: /You’ve subscribed to/)

    subscribe_to_subscriber_list(subscriber_list_id, expected_status: 200)
    subscribe_to_subscriber_list("missing",          expected_status: 404)
  end
end

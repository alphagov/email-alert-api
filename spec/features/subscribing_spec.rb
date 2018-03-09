RSpec.describe "Subscribing to a subscribable", type: :request do
  scenario "subscribing to a subscribable" do
    login_with_internal_app

    subscribable_id = create_subscribable

    subscribe_to_subscribable(subscribable_id, expected_status: 201)
    subscribe_to_subscribable(subscribable_id, expected_status: 200)
    subscribe_to_subscribable("missing",       expected_status: 404)
  end
end

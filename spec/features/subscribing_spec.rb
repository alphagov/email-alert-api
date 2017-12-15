RSpec.describe "Subscribing to a subscribable", type: :request do
  before do
    stub_govdelivery("UKGOVUK_1234")
  end

  scenario "subscribing to a subscribable" do
    subscribable_id = create_subscribable

    subscribe_to_subscribable(subscribable_id, expected_status: 201)
    subscribe_to_subscribable(subscribable_id, expected_status: 200)
    subscribe_to_subscribable("missing",       expected_status: 404)
  end
end

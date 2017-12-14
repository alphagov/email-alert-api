RSpec.describe "Missing a status update after three days", type: :request do
  before do
    stub_govdelivery("UKGOVUK_1234")
    stub_notify
  end

  scenario "when no status update has been received for an email" do
    subscribable_id = create_subscribable
    subscribe_to_subscribable(subscribable_id)
    create_content_change
    email_data = expect_an_email_was_sent

    Timecop.freeze(71.hours.from_now) do
      check_health_of_the_app
      expect(data.fetch(:status)).to eq("ok")
    end

    Timecop.freeze(73.hours.from_now) do
      check_health_of_the_app
      expect(data.fetch(:status)).to eq("warning")
    end

    Timecop.freeze(75.hours.from_now) do
      check_health_of_the_app
      expect(data.fetch(:status)).to eq("critical")

      reference = email_data.fetch(:reference)
      send_status_update(reference, "delivered")

      check_health_of_the_app
      expect(data.fetch(:status)).to eq("ok")
    end
  end
end

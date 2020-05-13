RSpec.describe Reports::EmailDeliveryAttempts do
  before do
    2.times do
      create(
        :delivery_attempt,
        status: "delivered",
        created_at: Time.zone.parse("2019-03-21T15:04:22.000000Z"),
        updated_at: Time.zone.parse("2019-03-22T06:10:44.000000Z"),
        sent_at: Time.zone.parse("2019-03-21T15:04:22.000000Z"),
      )
    end

    create(
      :delivery_attempt,
      status: "delivered",
      created_at: Time.zone.parse("2019-03-21T11:08:33.000000Z"),
      updated_at: Time.zone.parse("2019-03-22T016:22:43.000000Z"),
      sent_at: Time.zone.parse("2019-03-21T11:08:33.000000Z"),
    )

    create(:delivery_attempt, status: "sending")
    create(:delivery_attempt, status: "temporary_failure")
  end

  context "delivery attempt report" do
    let(:start_date) { "2019-03-21" }
    let(:end_date) { "2019-03-23" }

    it "throws an error if invalid date is used" do
      expect { described_class.new("xyz", end_date).report }.to raise_error(ArgumentError, "Date(s) entered need to be of date/time format")
    end

    it "outputs the average time between created_at and updated_at" do
      report_path = Rails.root.join("tmp/delivery_attempt_time_2019-03-2100:00:00+0000_to_2019-03-2300:00:00+0000.csv")
      expect { described_class.new(start_date, end_date).report }.to output(
        <<~TEXT,
          Searching for all sucessful delivery attempts between 2019-03-21 00:00:00 +0000 and 2019-03-23 00:00:00 +0000
          Calculating delivery attempt times...
          Finished! Average delivery attempt time between 2019-03-21 00:00:00 +0000 and 2019-03-23 00:00:00 +0000 is 71338.0s
          Report available at #{report_path}
        TEXT
      ).to_stdout
    end

    it "does not output the average time if there are no delivery attempts within date range" do
      expect { described_class.new("2019-02-02", "2019-02-01").report }.to raise_error(RuntimeError, "No data for dates provided")
    end
  end
end

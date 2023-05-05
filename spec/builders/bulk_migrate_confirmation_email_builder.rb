RSpec.describe BulkMigrateConfirmationEmailBuilder do
  describe ".call" do
    let(:source_subscriber_list) { create(:subscriber_list) }
    let(:destination_subscriber_list) { create(:subscriber_list) }
    let(:count) { 10 }

    around(:each) do |example|
      ClimateControl.modify(BULK_MIGRATE_CONFIRMATION_EMAIL_ACCOUNT: "test@test.uk") do
        example.run
      end
    end

    it "creates an email addressed to bulk migrate confirmation account" do
      described_class.call(
        source_id: source_subscriber_list.id,
        destination_id: destination_subscriber_list.id,
        count:,
      )

      presented_body = <<~BODY
        #{count} subscriptions have been migrated:
        From "#{source_subscriber_list.title}"
        To "#{destination_subscriber_list.title}"

        No email notification has been sent to users.

        Thanks
        GOV.UK emails
      BODY

      expected_email_attributes = {
        "subject" => "Bulk migration of #{source_subscriber_list.title} is complete",
        "body" => presented_body,
        "address" => "test@test.uk",
      }

      expect(Email.last.attributes).to include expected_email_attributes
    end
  end
end

RSpec.describe Reports::PotentiallyDeadListsReport do
  it "delegates to the subscriber list report" do
    inactive_list = create(:subscriber_list,
                           created_at: 2.years.ago)

    create(:subscription,
           subscriber_list: inactive_list,
           created_at: 13.months.ago)

    # active lists
    create(:subscription, created_at: 11.months.ago)
    create(:matched_content_change)
    create(:matched_message)

    # archivable list
    create(:subscriber_list)

    expect(Reports::SubscriberListsReport).to receive(:new)
      .with(Date.yesterday.to_s, slugs: inactive_list.slug)
      .and_call_original

    described_class.new.call
  end
end

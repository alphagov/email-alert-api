require "rails_helper"

RSpec.describe ContentChangeDeduplicatorService do
  it "removes duplicates preserving only the latest" do
    content_changes = [
      build(
        :content_change, id: 1,
        public_updated_at: 10.day.ago,
        content_id: "8e1fef7b-cd23-4dd2-84d0-61955203db61"
      ),
      latest_content_change = build(
        :content_change,
        public_updated_at: 1.days.ago,
        content_id: "8e1fef7b-cd23-4dd2-84d0-61955203db61"
      ),
      build(
        :content_change,
        public_updated_at: 5.days.ago,
        content_id: "8e1fef7b-cd23-4dd2-84d0-61955203db61"
      ),
      other_content_change = build(
        :content_change,
        public_updated_at: 1.hour.ago,
        content_id: "7575702c-0494-4791-a1af-150a40fa37f7"
      )
    ]

    expect(described_class.call(content_changes)).to eq(
      [other_content_change, latest_content_change]
    )
  end
end

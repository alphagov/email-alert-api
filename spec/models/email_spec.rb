RSpec.describe Email do
  describe ".timed_bulk_insert" do
    let(:records) do
      3.times.map do |i|
        {
          subject: "subject #{i}",
          body: "body #{i}",
          address: "#{i}@example.com",
          created_at: Time.zone.now,
          updated_at: Time.zone.now,
        }
      end
    end

    context "when we're inserting a full batch of emails" do
      it "times the insert" do
        expect(Metrics).to receive(:email_bulk_insert).and_call_original
        expect(described_class).to receive(:insert_all!).with(records)
        described_class.timed_bulk_insert(records, 3)
      end
    end

    context "when we're not inserting a full batch of emails" do
      it "doesn't time the insert" do
        expect(Metrics).not_to receive(:email_bulk_insert)
        expect(described_class).to receive(:insert_all!).with(records)
        described_class.timed_bulk_insert(records, 5)
      end
    end
  end
end

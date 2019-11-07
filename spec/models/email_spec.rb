RSpec.describe Email do
  describe "validations" do
    it "requires subject" do
      subject.valid?
      expect(subject.errors[:subject]).not_to be_empty
    end

    it "requires body" do
      subject.valid?
      expect(subject.errors[:body]).not_to be_empty
    end
  end

  describe ".timed_bulk_insert" do
    let(:columns) { %w[subject body address] }

    let(:records) do
      3.times.map { |i| ["subject #{i}", "body #{i}", "#{i}@example.com"] }
    end

    context "when we're inserting a full batch of emails" do
      it "times the insert" do
        expect(MetricsService).to receive(:email_bulk_insert).and_call_original
        expect(described_class).to receive(:import!).with(columns, records)
        described_class.timed_bulk_insert(columns, records, 3)
      end
    end

    context "when we're not inserting a full batch of emails" do
      it "doesn't time the insert" do
        expect(MetricsService).not_to receive(:email_bulk_insert)
        expect(described_class).to receive(:import!).with(columns, records)
        described_class.timed_bulk_insert(columns, records, 5)
      end
    end
  end
end

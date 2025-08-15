RSpec.describe Reports::HistoricalContentChangeStatisticsReport do
  let(:govuk_path) { "/government/base_path" }

  let(:expected) do
    <<~OUTPUT
      1 content changes registered for #{govuk_path}.

      Content change on #{Time.zone.now}:
       - notified immediately: 0
       - notified next day:    0
       - notified at weekend:  0
       - notified total:       0
    OUTPUT
  end

  it "does not return any content changes if path does not have any" do
    expect(described_class.new(govuk_path).call).to eq("No content changes registered for path: #{govuk_path}")
  end

  it "returns data on content changes for valid path" do
    create(:content_change, base_path: govuk_path)

    expect(described_class.new(govuk_path).call).to eq expected
  end
end

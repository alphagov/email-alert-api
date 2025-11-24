RSpec.describe PrometheusMetrics do
  describe ".register" do
    it "registers the prometheus metrics" do
      described_class::GAUGES.each do |gauge|
        expect(PrometheusExporter::Client.default)
          .to receive(:register)
          .with(:gauge, "#{described_class::PREFIX}#{gauge[:name]}", gauge[:description])
      end

      described_class.register
    end
  end

  describe ".name_with_prefix" do
    it "prefixes the metric name with 'email_alert_api_'" do
      expect(described_class.name_with_prefix("total_unprocessed_content_changes"))
        .to eq("email_alert_api_total_unprocessed_content_changes")
    end
  end
end

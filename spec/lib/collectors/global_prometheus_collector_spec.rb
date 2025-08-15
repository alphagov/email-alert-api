RSpec.describe Collectors::GlobalPrometheusCollector do
  describe "#type" do
    it "returns the type" do
      expect(described_class.new.type).to eq("email_alert_api_global")
    end
  end

  describe "#metrics" do
    let(:metrics) { described_class.new.metrics }

    it "does not return an empty array" do
      expect(metrics).to be_an_instance_of(Array)
      expect(metrics.count).to be > 0
    end

    it "returns an array of configured alerts" do
      expect(metrics).to be_an_instance_of(Array)
      expect(metrics.count).to eq(4)
    end

    it "includes number of medical alerts being checked" do
      expect(metrics[0].name).to eq("email_alert_api_current_medical_safety_alerts")
      expect(metrics[0].help).to eq("Number of medical safety alerts email-alert-api is checking")
      expect(metrics[0].data).to eq({} => 0)
    end

    it "includes number of medical alerts marked as delivered" do
      expect(metrics[1].name).to eq("email_alert_api_delivered_medical_safety_alerts")
      expect(metrics[1].help).to eq("Number of current medical safety alerts marked as delivered")
      expect(metrics[1].data).to eq({} => 0)
    end

    it "includes number of travel alerts being checked" do
      expect(metrics[2].name).to eq("email_alert_api_current_travel_advice_alerts")
      expect(metrics[2].help).to eq("Number of travel advice alerts email-alert-api is checking")
      expect(metrics[2].data).to eq({} => 0)
    end

    it "includes number of travel alerts marked as delivered" do
      expect(metrics[3].name).to eq("email_alert_api_delivered_travel_advice_alerts")
      expect(metrics[3].help).to eq("Number of current travel advice alerts marked as delivered")
      expect(metrics[3].data).to eq({} => 0)
    end
  end
end

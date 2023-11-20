RSpec.describe AlertCheckWorker do
  include SearchAlertListHelpers

  describe "#perform", caching: true do
    def perform
      described_class.new.perform("medical_safety_alert")
    end

    context "there are no alerts older than an hour" do
      before { stub_medical_safety_alert_feed(content_id: SecureRandom.uuid, age: 30.minutes) }

      it "should put 0/0 in the cache" do
        expect(Rails.cache).to receive(:write).with("current_medical_safety_alerts", 0, expires_in: 15.minutes)
        expect(Rails.cache).to receive(:write).with("delivered_medical_safety_alerts", 0, expires_in: 15.minutes)
        perform
      end
    end

    context "there are no alerts younger than 2 days" do
      before { stub_medical_safety_alert_feed(content_id: SecureRandom.uuid, age: 3.days) }

      it "should put 0/0 in the cache" do
        expect(Rails.cache).to receive(:write).with("current_medical_safety_alerts", 0, expires_in: 15.minutes)
        expect(Rails.cache).to receive(:write).with("delivered_medical_safety_alerts", 0, expires_in: 15.minutes)
        perform
      end
    end

    context "there is a valid alert with delivered emails" do
      before do
        content_id = SecureRandom.uuid
        stub_medical_safety_alert_feed(content_id:, age: 2.hours)
        create(:email, content_id:, notify_status: "delivered")
      end

      it "should put 1/1 in the cache" do
        expect(Rails.cache).to receive(:write).with("current_medical_safety_alerts", 1, expires_in: 15.minutes)
        expect(Rails.cache).to receive(:write).with("delivered_medical_safety_alerts", 1, expires_in: 15.minutes)
        perform
      end
    end

    context "there is a valid alerts with undelivered emails" do
      before do
        content_id = SecureRandom.uuid
        stub_medical_safety_alert_feed(content_id:, age: 2.hours)
        create(:email, content_id:, notify_status: nil)
      end

      it "should put 1/0 in the cache" do
        expect(Rails.cache).to receive(:write).with("current_medical_safety_alerts", 1, expires_in: 15.minutes)
        expect(Rails.cache).to receive(:write).with("delivered_medical_safety_alerts", 0, expires_in: 15.minutes)
        perform
      end
    end

    context "there is a valid alert with delivered emails that are too old to be valid" do
      before do
        content_id = SecureRandom.uuid
        stub_medical_safety_alert_feed(content_id:, age: 2.hours)
        create(:email, content_id:, notify_status: "delivered", created_at: Time.zone.now - 3.hours)
      end

      it "should put 1/0 in the cache" do
        expect(Rails.cache).to receive(:write).with("current_medical_safety_alerts", 1, expires_in: 15.minutes)
        expect(Rails.cache).to receive(:write).with("delivered_medical_safety_alerts", 0, expires_in: 15.minutes)
        perform
      end
    end
  end
end

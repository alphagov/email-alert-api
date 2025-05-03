RSpec.describe PollingAlertCheckJob do
  include SearchAlertListHelpers
  include NotifyRequestHelpers

  def expect_cache_flags_to_contain(current, delivered)
    expect(Rails.cache).to receive(:write) do |name, count, hash|
      expect(name).to eq("current_medical_safety_alerts")
      expect(count).to eq(current)
      expect(hash[:expires_at]).to be_within(5.seconds).of(Time.zone.now + 30.minutes)
    end

    expect(Rails.cache).to receive(:write) do |name, count, hash|
      expect(name).to eq("delivered_medical_safety_alerts")
      expect(count).to eq(delivered)
      expect(hash[:expires_at]).to be_within(5.seconds).of(Time.zone.now + 30.minutes)
    end
  end

  describe "#perform", caching: true do
    def perform
      described_class.new.perform("medical_safety_alert")
    end

    context "there are no email alerts older than an hour" do
      before { stub_medical_safety_alert_query(content_id: SecureRandom.uuid, age: 30.minutes) }

      it "should put 0/0 in the cache" do
        expect_cache_flags_to_contain(0, 0)

        perform
      end
    end

    context "there are no email alerts younger than 2 days" do
      before { stub_medical_safety_alert_query(content_id: SecureRandom.uuid, age: 3.days) }

      it "should put 0/0 in the cache" do
        expect_cache_flags_to_contain(0, 0)

        perform
      end
    end

    context "there is a valid email alert with delivered emails" do
      before do
        content_id = SecureRandom.uuid
        stub_medical_safety_alert_query(content_id:, age: 2.hours)
        create(:email, content_id:, notify_status: "delivered", status: "sent")
      end

      it "should put 1/1 in the cache" do
        expect_cache_flags_to_contain(1, 1)

        perform
      end
    end

    context "there is a valid email alert with undelivered emails" do
      before do
        content_id = SecureRandom.uuid
        stub_medical_safety_alert_query(content_id:, age: 2.hours)
        email = create(:email, content_id:, notify_status: nil, status: "sent")
        stub_notify_email_delivery_status_delivered_empty(email.id)
      end

      it "should put 1/0 in the cache" do
        expect_cache_flags_to_contain(1, 0)

        perform
      end
    end

    context "there is a valid email alert with undelivered emails but polling confirms they were actually delivered" do
      let(:content_id) { SecureRandom.uuid }

      before do
        stub_medical_safety_alert_query(content_id:, age: 2.hours)
        email1 = create(:email, content_id:, notify_status: nil, status: "sent")
        email2 = create(:email, content_id:, notify_status: nil, status: "sent")
        stub_notify_email_delivery_status_delivered_empty(email1.id)
        stub_notify_email_delivery_status_delivered(email2.id)
      end

      it "should put 1/1 in the cache" do
        expect_cache_flags_to_contain(1, 1)

        perform
      end

      it "doesn't poll Notify once it's found a delivered email" do
        email3 = create(:email, content_id:, notify_status: nil, status: "sent")
        request = stub_notify_email_delivery_status_delivered(email3.id)
        perform
        expect(request).not_to have_been_made
      end
    end

    context "there is a valid email alert but the delivered emails are too old to have been caused by it" do
      before do
        content_id = SecureRandom.uuid
        stub_medical_safety_alert_query(content_id:, age: 2.hours)
        create(:email, content_id:, notify_status: "delivered", created_at: Time.zone.now - 3.hours, status: "sent")
      end

      it "should put 1/0 in the cache" do
        expect_cache_flags_to_contain(1, 0)

        perform
      end
    end
  end
end

RSpec.describe "alert_listeners" do
  describe "verify_or_create" do
    before do
      Rake::Task["alert_listeners:verify_or_create"].reenable
      create(:subscriber_list, :travel_advice)
      create(:subscriber_list, :medical_safety_alert)
    end

    around(:each) do |example|
      ClimateControl.modify(ALERT_LISTENER_EMAIL_ACCOUNT: "test@example.com") do
        example.run
      end
    end

    context "with no existing records" do
      it "builds emails for a subscriber list" do
        expect { Rake::Task["alert_listeners:verify_or_create"].invoke }.to output.to_stdout

        subs = Subscriber.where(address: "test@example.com")
        expect(subs.count).to eq(1)
        list_slugs = subs.first.subscriptions.map { |s| s.subscriber_list.slug }
        expect(list_slugs).to match_array(ALERT_SLUGS)
      end
    end

    context "with existing records" do
      before do
        subscriber = Subscriber.create!(address: "test@example.com")
        ALERT_SLUGS.each do |slug|
          Subscription.find_or_create_by!(
            subscriber:,
            subscriber_list: SubscriberList.where(slug:).first,
            frequency: "immediately",
            source: "support_task",
          )
        end
      end

      it "builds emails for a subscriber list" do
        expect { Rake::Task["alert_listeners:verify_or_create"].invoke }.to output.to_stdout

        subs = Subscriber.where(address: "test@example.com")
        expect(subs.count).to eq(1)
        list_slugs = subs.first.subscriptions.map { |s| s.subscriber_list.slug }
        expect(list_slugs).to match_array(ALERT_SLUGS)
      end
    end

    context "when alert listener hasn't been set" do
      it "aborts with an error" do
        ENV["ALERT_LISTENER_EMAIL_ACCOUNT"] = nil

        expect { Rake::Task["alert_listeners:verify_or_create"].invoke }.to raise_error(SystemExit, /Can't create listener: ALERT_LISTENER_EMAIL_ACCOUNT env var missing!/)
      end
    end

    context "when subscriber list is missing" do
      it "aborts with an error" do
        SubscriberList.first.delete

        expect { Rake::Task["alert_listeners:verify_or_create"].invoke }.to raise_error(SystemExit, /Can't create listener: one or more subscriber_lists missing/)
      end
    end
  end
end

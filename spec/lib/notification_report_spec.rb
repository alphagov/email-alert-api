require "rails_helper"

RSpec.describe NotificationReport do
  Entry = NotificationReport::Entry
  Printer = NotificationReport::Printer

  subject { described_class.all }

  it "has an entry per request id" do
    create(:notification_log, govuk_request_id: "a")
    create(:notification_log, govuk_request_id: "b")
    create(:notification_log, govuk_request_id: "a")

    expect(subject.entries.count).to eq(2)
  end

  describe Entry do
    let(:entry) { Entry.new("request_id", NotificationLog.all) }

    it "reports the notifications sent from each app" do
      x = create(:notification_log, emailing_app: "email_alert_api")
      y = create(:notification_log, emailing_app: "gov_uk_delivery")
      z = create(:notification_log, emailing_app: "gov_uk_delivery")

      expect(entry.email_alert_api_notifications).to match_array [x]
      expect(entry.gov_uk_delivery_notifications).to match_array [y, z]
    end

    describe "#topics_matched_in_both_systems" do
      it "reports the intersection of gov_delivery_ids" do
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
        create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(b c d))

        expect(entry.topics_matched_in_both_systems).to match_array %w(b c)
      end

      it "returns an empty array if a notification wasn't sent from either app" do
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
        expect(entry.topics_matched_in_both_systems).to be_empty
      end

      context "when multiple notifications were sent from a system" do
        before do
          create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))

          create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(b c d))
          create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(c d))
        end

        it "uses the gov_delivery_ids of the last notification log" do
          expect(entry.topics_matched_in_both_systems).to eq %w(c)
        end
      end
    end

    describe "#topics_matched_in_email_alert_api_only" do
      it "reports the subtraction of gov_delivery_ids" do
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
        create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(c d))

        expect(entry.topics_matched_in_email_alert_api_only).to match_array %w(a b)
      end
    end

    describe "#topics_matched_in_govuk_delivery_only" do
      it "reports the subtraction of gov_delivery_ids" do
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
        create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(c d))

        expect(entry.topics_matched_in_govuk_delivery_only).to eq %w(d)
      end
    end

    describe "#email_alert_api_notifications_have_the_same_topics" do
      it "reports true if all topics are the same" do
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))

        expect(entry.email_alert_api_notifications_have_the_same_topics).to eq(true)
      end

      it "reports false if some topics are different" do
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b))

        expect(entry.email_alert_api_notifications_have_the_same_topics).to eq(false)
      end
    end

    describe "#govuk_delivery_notifications_have_the_same_topics" do
      it "reports true if all topics are the same" do
        create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b c))
        create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b c))

        expect(entry.gov_uk_delivery_notifications_have_the_same_topics).to eq(true)
      end

      it "reports false if some topics are different" do
        create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b c))
        create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b))

        expect(entry.gov_uk_delivery_notifications_have_the_same_topics).to eq(false)
      end
    end
  end

  describe Printer do
    let(:entry) { Entry.new("request_id", NotificationLog.all) }

    it "prints some validation/consistency checks" do
      create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c d e))
      create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c d e))

      create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(c d))
      create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(c d e f))

      print = -> { described_class.print(entry) }

      expect(print).to output(/request_id/).to_stdout
      expect(print).to output(/2 notifications from email-alert-api/).to_stdout
      expect(print).to output(/topics are the same for these notifications/).to_stdout
      expect(print).to output(/2 notifications from govuk-delivery/).to_stdout
      expect(print).to output(/topics are different for these notifications/).to_stdout
      expect(print).to output(/3 topics matched in both systems/).to_stdout
      expect(print).to output(/2 topics matched in email-alert-api but not in govuk-delivery/).to_stdout
      expect(print).to output(/1 topics matched in govuk-delivery but not in email-alert-api/).to_stdout
    end

    context "when a notification wasn't sent from govuk_delivery" do
      before do
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c d e))
      end

      it "doesn't print the checks to make the output less noisy" do
        print = -> { described_class.print(entry) }
        expect(print).not_to output(/notifications from email-alert-api/).to_stdout
      end
    end

    context "when all the checks pass" do
      before do
        create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
        create(:notification_log, emailing_app: "gov_delivery_ids", gov_delivery_ids: %w(a b c))
      end

      it "doesn't print the checks to make the output less noisy" do
        print = -> { described_class.print(entry) }
        expect(print).not_to output(/notifications from email-alert-api/).to_stdout
      end
    end
  end
end

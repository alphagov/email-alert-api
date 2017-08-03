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

    describe "#all_ok?" do
      context "when everything matches" do
        it "returns true" do
          create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
          create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b c))

          expect(entry.all_ok?).to be_truthy
        end
      end

      context "when no govuk delivery notifications exist" do
        it "returns true" do
          create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))

          expect(entry.all_ok?).to be_truthy
        end
      end

      context "when there are mismatches" do
        context "there are multiple email alert api notifications" do
          it "returns false" do
            create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
            create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
            create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b c))

            expect(entry.all_ok?).to be_falsey
          end
        end

        context "there are multiple govuk_delivery notifications" do
          it "returns false" do
            create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
            create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b c))
            create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b c))

            expect(entry.all_ok?).to be_falsey
          end
        end

        context "when there are no topics matched in both systems" do
          it "returns false" do
            create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
            create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(d e f))

            expect(entry.all_ok?).to be_falsey
          end
        end

        context "when there are topics only matched in email alert api" do
          it "returns false" do
            create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c))
            create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a))

            expect(entry.all_ok?).to be_falsey
          end
        end

        context "when there are topics only matched in govuk_delivery" do
          it "returns false" do
            create(:notification_log, emailing_app: "email_alert_api", gov_delivery_ids: %w(a))
            create(:notification_log, emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b c))

            expect(entry.all_ok?).to be_falsey
          end
        end
      end
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

  describe NotificationReport::CsvExporter do
    let(:entries) { NotificationReport.all.entries }
    let(:exporter) { described_class.new(entries) }

    before do
      create(:notification_log, govuk_request_id: "1234-5678", content_id: "9876-5432", emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c), created_at: "2017-08-02 01:00:00 UTC")
      create(:notification_log, govuk_request_id: "1234-5678", content_id: "9876-5432", emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(a b c), created_at: "2017-08-02 01:00:01 UTC")

      create(:notification_log, govuk_request_id: "1111-2222", content_id: "3333-4444", emailing_app: "email_alert_api", gov_delivery_ids: %w(a b c), created_at: "2017-08-01 01:00:00 UTC")
      create(:notification_log, govuk_request_id: "1111-2222", content_id: "3333-4444", emailing_app: "gov_uk_delivery", gov_delivery_ids: %w(c d e), created_at: "2017-08-01 01:00:01 UTC")
    end

    it "exports the report to CSV format with headings" do
      expected_headers = "govuk_request_id,"\
                         "content_id,"\
                         "document_type,"\
                         "email_doc_supertype,"\
                         "govt_doc_supertype,"\
                         "created_at,"\
                         "all_ok?,"\
                         "email_alert_api_notifications.count,"\
                         "gov_uk_delivery_notifications.count,"\
                         "email_alert_api_notifications_have_the_same_topics,"\
                         "gov_uk_delivery_notifications_have_the_same_topics,"\
                         "topics_matched_in_both_systems,"\
                         "topics_matched_in_email_alert_api_only,"\
                         "topics_matched_in_govuk_delivery_only\n"

      expected_matched_row = "1234-5678,9876-5432,announcement,\"\",\"\",2017-08-02 01:00:00 UTC,true,1,1,true,true,\"a,b,c\",\"\",\"\"\n"
      expected_mismatched_row = "1111-2222,3333-4444,announcement,\"\",\"\",2017-08-01 01:00:00 UTC,false,1,1,true,true,c,\"a,b\",\"d,e\"\n"

      StringIO.open do |io|
        exporter.export(io)
        expect(io.string).to include(expected_headers)
        expect(io.string).to include(expected_matched_row)
        expect(io.string).to include(expected_mismatched_row)
      end
    end
  end
end

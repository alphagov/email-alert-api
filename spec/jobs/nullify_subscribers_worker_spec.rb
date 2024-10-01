require "spec_helper"
require "gds_api/test_helpers/account_api"

RSpec.describe NullifySubscribersWorker do
  include GdsApi::TestHelpers::AccountApi

  describe ".perform" do
    context "when subscribers are older than the nullifyable period" do
      let(:nullifyable_time) { 29.days.ago }

      before do
        @subscriber = create(:subscriber, created_at: nullifyable_time)
      end

      it "nullifies subscribers that don't have any subscriptions" do
        expect { subject.perform }
          .to change { Subscriber.nullified.count }.by(1)
      end

      it "nullifies subscribers that don't have any recent active subscriptions" do
        create(:subscription, :ended, ended_at: nullifyable_time, subscriber: @subscriber)

        expect { subject.perform }
          .to change { Subscriber.nullified.count }.by(1)
      end

      context "when the subscriber has a govuk_account_id" do
        it "deletes them from account-api" do
          create(:subscriber, govuk_account_id: "sub", created_at: nullifyable_time)
          stub = stub_account_api_delete_user_by_subject_identifier(subject_identifier: "sub")
          subject.perform
          expect(stub).to have_been_made
        end

        it "gracefully handles account-apit record missing, nullifies both local accounts" do
          create(:subscriber, govuk_account_id: "sub", created_at: nullifyable_time)
          stub = stub_account_api_delete_user_by_subject_identifier_does_not_exist(subject_identifier: "sub")
          expect { subject.perform }
            .to change { Subscriber.nullified.count }.by(2)
          expect(stub).to have_been_made
        end
      end

      it "doesn't nullify subscribers with recently ended subscriptions" do
        create(:subscription, :ended, subscriber: @subscriber)

        expect { subject.perform }
          .to_not(change { Subscriber.nullified.count })
      end

      it "doesn't nullify subscribers with active subscriptions" do
        create(:subscription, subscriber: @subscriber)

        expect { subject.perform }
          .to_not(change { Subscriber.nullified.count })
      end
    end

    it "doesn't nullify subscribers which have been created recently" do
      create(:subscriber)

      expect { subject.perform }
        .to_not(change { Subscriber.nullified.count })
    end
  end
end

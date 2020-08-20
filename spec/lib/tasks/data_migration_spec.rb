RSpec.describe "data_migration" do
  include NotifyRequestHelpers

  describe "switch_to_daily_digest" do
    let(:list1) { create :subscriber_list }
    let(:list2) { create :subscriber_list }

    before do
      Rake::Task["data_migration:switch_to_daily_digest"].reenable
      stub_notify
    end

    it "switches immediate subscriptions to daily" do
      subscription = create :subscription, subscriber_list: list1, frequency: :immediately

      expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke(list1.slug, list2.slug) }
        .to output.to_stdout

      new_subscription = subscription.subscriber.subscriptions.active.first

      expect(subscription.reload).to be_ended
      expect(subscription.ended_reason).to eq "bulk_immediate_to_digest"

      expect(new_subscription.frequency).to eq "daily"
      expect(new_subscription.source).to eq "bulk_immediate_to_digest"
    end

    it "does not change other subscriptions" do
      create :subscription, subscriber_list: list1, frequency: :daily
      create :subscription, frequency: :immediately

      expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke(list1.slug) }
        .to raise_error("No subscriptions to change")
    end

    it "sends a summary email to affected subscribers" do
      subscriber = create :subscriber
      create :subscription, subscriber_list: list1, frequency: :immediately, subscriber: subscriber
      create :subscription, subscriber_list: list2, frequency: :immediately, subscriber: subscriber

      expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke(list1.slug, list2.slug) }
        .to output.to_stdout

      email_data = expect_an_email_was_sent
      expect(email_data[:email_address]).to eq(subscriber.address)
      expect(email_data[:personalisation][:subject]).to eq("Your GOV.UK email subscriptions")
      expect(email_data[:personalisation][:body]).to include(list1.title)
      expect(email_data[:personalisation][:body]).to include(list2.title)
    end

    context "when a list is not found" do
      it "raises an error" do
        expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke(list1.slug, "foo") }
          .to raise_error("One or more lists were not found")
      end
    end

    context "when the change fails for a subscriber" do
      let!(:subscription1) { create :subscription, subscriber_list: list1, frequency: :immediately }
      let!(:subscription2) { create :subscription, subscriber_list: list1, frequency: :immediately }

      before do
        allow(Subscription).to receive(:insert_all!).and_call_original

        allow(Subscription)
          .to receive(:insert_all!)
          .with(array_including([hash_including(subscriber_id: subscription2.subscriber_id)]))
          .and_raise("An error")
      end

      it "only sends an email to switched subscribers" do
        expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke(list1.slug) }
          .to output.to_stdout
          .and change { Email.count }.by(1)
      end

      it "persists changes for other subscribers" do
        expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke(list1.slug) }
          .to output.to_stdout
          .and change { Subscription.count }.by(1)

        expect(subscription2.reload).to_not be_ended
      end
    end
  end
end

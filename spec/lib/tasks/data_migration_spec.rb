RSpec.describe "data_migration" do
  include NotifyRequestHelpers

  describe "switch_to_daily_digest" do
    let!(:list1) { create :subscriber_list }
    let!(:list2) { create :subscriber_list }
    let(:list_data) do
      [
        { "slug" => list1.slug },
        { "slug" => list2.slug },
      ]
    end

    before do
      allow(CSV).to receive(:open).and_return(list_data)
      Rake::Task["data_migration:switch_to_daily_digest"].reenable
      stub_notify
    end

    around do |example|
      ClimateControl.modify(GOVUK_NOTIFY_RECIPIENTS: "*") do
        stub_notify
        example.run
      end
    end

    it "switches immediate subscriptions to daily" do
      subscription = create :subscription, subscriber_list: list1, frequency: :immediately

      expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke }
        .to output.to_stdout

      new_subscription = subscription.subscriber.subscriptions.active.first

      expect(subscription.reload).to be_ended
      expect(subscription.ended_reason).to eq "bulk_immediate_to_digest"

      expect(new_subscription.frequency).to eq "daily"
      expect(new_subscription.source).to eq "bulk_immediate_to_digest"
    end

    it "does not change other subscriptions" do
      digest = create :subscription, subscriber_list: list1, frequency: :daily
      non_list = create :subscription, frequency: :immediately

      expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke }
        .to output.to_stdout

      expect(digest.reload).not_to be_ended
      expect(non_list.reload).not_to be_ended
    end

    it "respects any reverted subscriptions" do
      subscriber = create :subscriber
      create :subscription, :ended, subscriber_list: list1, frequency: :daily, source: :bulk_immediate_to_digest, subscriber: subscriber
      reverted_subscription = create :subscription, subscriber_list: list1, frequency: :immediately, subscriber: subscriber
      other_subscription = create :subscription, subscriber_list: list2, frequency: :immediately, subscriber: subscriber

      expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke }
        .to output.to_stdout

      expect(reverted_subscription.reload).not_to be_ended
      expect(other_subscription.reload).to be_ended
    end

    it "sends a summary email to affected subscribers" do
      subscriber = create :subscriber
      create :subscription, subscriber_list: list1, frequency: :immediately, subscriber: subscriber
      create :subscription, subscriber_list: list2, frequency: :immediately, subscriber: subscriber

      expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke }
        .to output.to_stdout

      email_data = expect_an_email_was_sent
      expect(email_data[:email_address]).to eq(subscriber.address)
      expect(email_data[:personalisation][:subject]).to eq("Your GOV.UK email subscriptions")
      expect(email_data[:personalisation][:body]).to include(list1.title)
      expect(email_data[:personalisation][:body]).to include(list2.title)
    end

    context "when a list is not found" do
      let(:list_data) do
        [{ "slug" => "missing-list" }]
      end

      it "raises an error" do
        expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke }
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
        expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke }
          .to output.to_stdout
          .and change { Email.count }.by(1)
      end

      it "persists changes for other subscribers" do
        expect { Rake::Task["data_migration:switch_to_daily_digest"].invoke }
          .to output.to_stdout
          .and change { Subscription.count }.by(1)

        expect(subscription2.reload).to_not be_ended
      end
    end
  end

  describe "update_subscriber_list_tag" do
    before do
      Rake::Task["data_migration:update_subscriber_list_tag"].reenable
    end

    it "renames a country in a 'destination_country' tag" do
      list = create :subscriber_list, tags: { location: { any: %w[old other] } }

      expect {
        Rake::Task["data_migration:update_subscriber_list_tag"].invoke("location", "old", "new")
      }.to output.to_stdout

      expect(list.reload.tags[:location][:any]).to match_array %w[new other]
    end

    it "does not update a list without a matching tag" do
      list = create :subscriber_list, tags: { location: { any: %w[other] } }
      Rake::Task["data_migration:update_subscriber_list_tag"].invoke("location", "old", "new")
      expect(list.reload.tags[:location][:any]).to match_array %w[other]
    end
  end
end

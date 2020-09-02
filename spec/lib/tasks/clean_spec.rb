RSpec.describe "clean" do
  describe "close_fco_dfid_subscriptions" do
    let(:fco_content_id) { "db994552-7644-404d-a770-a2fe659c661f" }
    let(:dfid_content_id) { "9adfc4ed-9f6c-4976-a6d8-18d34356367c" }

    before { Rake::Task["clean:close_fco_dfid_subscriptions"].reenable }

    around do |example|
      expect { example.run }.to output.to_stdout
    end

    it "closes subscriptions to FCO and DFID lists" do
      fco_subscriber_list = create(
        :subscriber_list_with_subscribers,
        links: { organisations: { any: [fco_content_id] } },
      )

      dfid_subscriber_list = create(
        :subscriber_list_with_subscribers,
        links: { organisations: { any: [dfid_content_id] } },
      )

      fco_and_dfid_subscriber_list = create(
        :subscriber_list_with_subscribers,
        links: { organisations: { any: [fco_content_id, dfid_content_id] } },
      )

      scope = Subscription.active.where(
        subscriber_list: [fco_subscriber_list,
                          dfid_subscriber_list,
                          fco_and_dfid_subscriber_list],
      )

      expect { Rake::Task["clean:close_fco_dfid_subscriptions"].invoke }
        .to change { scope.count }.to(0)
    end

    it "doesn't close subscriptions to lists with other organisations" do
      other_orgs_subscriber_list = create(
        :subscriber_list_with_subscribers,
        links: { organisations: { any: [fco_content_id, SecureRandom.uuid] } },
      )

      scope = Subscription.active.where(subscriber_list: [other_orgs_subscriber_list])

      expect { Rake::Task["clean:close_fco_dfid_subscriptions"].invoke }
        .not_to change { scope.exists? }.from(true)
    end
  end
end

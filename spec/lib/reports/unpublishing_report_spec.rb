RSpec.describe Reports::UnpublishingReport do
  before do
    subscriber_one = create(:subscriber)
    subscriber_two = create(:subscriber)

    unpublished_subscription = create(:subscriber_list, title: "Unpublished subscription")
    create(
      :subscription,
      :unpublished,
      subscriber_list: unpublished_subscription,
      subscriber: subscriber_one,
      ended_at: "2018-08-29 13:04:03",
    )

    create(
      :subscription,
      :unpublished,
      subscriber_list: unpublished_subscription,
      subscriber: subscriber_two,
      ended_at: "2018-08-29 13:04:03",
    )

    new_subscription = create(:subscriber_list, title: "Newly subscribed title")
    create(
      :subscription,
      subscriber: subscriber_one,
      subscriber_list: new_subscription,
      created_at: "2018-09-21 15:00:03",
    )

    create(
      :subscription,
      subscriber: subscriber_two,
      subscriber_list: new_subscription,
      created_at: "2018-09-18 9:20:08",
    )

    subscriber_three = create(:subscriber)
    unpublished_subscription_two = create(:subscriber_list, title: "Unpublished subscription two")
    create(
      :subscription,
      :unpublished,
      subscriber_list: unpublished_subscription_two,
      subscriber: subscriber_three,
      ended_at: "2018-08-31 20:40:03",
    )
  end

  context "generates report" do
    it "generates a report showing unpublishing activity and new subscriptions being made" do
      described_class.call("2018/08/28", "2018/08/30")
      expect { described_class.call("2018/08/28", "2018/08/30") }.to output(
        <<~TEXT,
          Unpublishing activity between 2018-08-28 00:00:00 and 2018-08-30 00:00:00

          'Unpublished subscription' has been unpublished ending 2 subscriptions

          - 2 subscribers have now subscribed to 'Newly subscribed title'
          -------------------------------------------
        TEXT
      ).to_stdout
    end

    it "generates a report showing unpublishing activity but no new subscriptions being created" do
      described_class.call("2018/08/31", "2018/09/01")
      expect { described_class.call("2018/08/31", "2018/09/01") }.to output(
        <<~TEXT,
          Unpublishing activity between 2018-08-31 00:00:00 and 2018-09-01 00:00:00

          'Unpublished subscription two' has been unpublished ending 1 subscriptions

          -------------------------------------------
        TEXT
      ).to_stdout
    end

    it "doesn't generate any results as nothing has been unpublished in the time frame" do
      expect { described_class.call("2018/08/10", "2018/08/11") }.to output(
        "Unpublishing activity between 2018-08-10 00:00:00 and 2018-08-11 00:00:00\n\n",
      ).to_stdout
    end
  end
end

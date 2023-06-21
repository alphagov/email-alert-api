RSpec.describe BadListSubscriptionsMigrator do
  describe "#process_all_lists" do
    let(:prefix) { "topic" }

    let(:taxonomy_topic_one_base_params) do
      {
        title: "T Levels",
        url: "/education/t-levels",
      }
    end

    let(:taxonomy_topic_two_base_params) do
      {
        title: "Lasting power of attorney, being in care and managing finances",
        url: "/life-circumstances/lasting-power-attorney",
      }
    end

    let!(:taxonomy_topic_one_good_list) do
      SubscriberList.create!(
        taxonomy_topic_one_base_params.merge(
          slug: "t-levels",
          links: { "taxon_tree" => { "any" => %w[d27447bd-86db-4a97-aed1-ac2049431513] } },
          content_id: nil,
        ),
      )
    end

    let!(:taxonomy_topic_one_bad_list) do
      SubscriberList.create!(
        taxonomy_topic_one_base_params.merge(
          slug: "t-levels-7333acacbe",
          links: {},
          content_id: "d27447bd-86db-4a97-aed1-ac2049431513",
        ),
      )
    end

    let!(:taxonomy_topic_two_good_list) do
      SubscriberList.create!(
        taxonomy_topic_two_base_params.merge(
          slug: "lasting-power-of-attorney-being-in-care-and-your-financial-affairs",
          links: { "taxon_tree" => { "any" => %w[6bf58181-7ebe-4599-8a93-281f9b7af810] } },
          content_id: nil,
        ),
      )
    end

    let!(:taxonomy_topic_two_bad_list) do
      SubscriberList.create!(
        taxonomy_topic_two_base_params.merge(
          slug: "lasting-power-of-attorney-being-in-care-and-managing-finances",
          links: {},
          content_id: "6bf58181-7ebe-4599-8a93-281f9b7af810",
        ),
      )
    end

    context "when the destination subscriber list has active subscriptions" do
      before do
        create(:subscription, subscriber_list: taxonomy_topic_two_good_list)
        create(:subscription, subscriber_list: taxonomy_topic_one_good_list)
        create(:subscription, subscriber_list: taxonomy_topic_two_bad_list)
        create(:subscription, subscriber_list: taxonomy_topic_one_bad_list)
      end

      it "calls the SubscriberListMover" do
        remover = described_class.new
        list_mover_double = double("SubscriberListMover")
        expect(list_mover_double).to receive(:call).twice
        expect(taxonomy_topic_two_good_list.active_subscriptions_count).to be 1
        expect(taxonomy_topic_one_good_list.active_subscriptions_count).to be 1

        allow(SubscriberListMover)
          .to receive(:new)
          .with(from_slug: "lasting-power-of-attorney-being-in-care-and-managing-finances", to_slug: "lasting-power-of-attorney-being-in-care-and-your-financial-affairs")
          .and_return(list_mover_double)

        allow(SubscriberListMover)
          .to receive(:new)
          .with(from_slug: "t-levels-7333acacbe", to_slug: "t-levels")
          .and_return(list_mover_double)

        remover.process_all_lists
      end
    end

    context "when the destination subscriber list has no active subscriptions" do
      it "does not call the SubscriberListMover" do
        remover = described_class.new
        list_mover_double = double("SubscriberListMover")

        expect(taxonomy_topic_two_good_list.active_subscriptions_count).to be 0
        expect(taxonomy_topic_one_good_list.active_subscriptions_count).to be 0
        expect(list_mover_double).not_to receive(:call)

        remover.process_all_lists
      end
    end

    context "when the bad subscriber_list has no active subscriptions" do
      before do
        create(:subscription, subscriber_list: taxonomy_topic_two_good_list)
        create(:subscription, subscriber_list: taxonomy_topic_one_good_list)
      end

      it "does not call the SubscriberListMover" do
        remover = described_class.new
        list_mover_double = double("SubscriberListMover")

        expect(list_mover_double).not_to receive(:call)

        remover.process_all_lists

        expect(taxonomy_topic_two_good_list.active_subscriptions_count).to be 1
        expect(taxonomy_topic_one_good_list.active_subscriptions_count).to be 1
      end
    end
  end
end

RSpec.describe BadListSubscriptionsMigrator do
  describe "#process_all_lists" do
    let(:prefix) { "topic" }

    let(:child_benefit_base_params) do
      {
        title: "Child Benefit",
        url: "/topic/benefits-credits/child-benefit",
      }
    end

    let(:tax_credit_base_params) do
      {
        title: "Tax credits",
        url: "/topic/benefits-credits/tax-credits",
      }
    end

    let!(:child_benefit_good_list) do
      SubscriberList.create!(
        child_benefit_base_params.merge(
          slug: "tax-credits-and-child-benefit-child-benefit",
          links: { "topics" => { "any" => %w[cc9eb8ab-7701-43a7-a66d-bdc5046224c0] } },
          content_id: nil,
        ),
      )
    end

    let!(:child_benefit_bad_list) do
      SubscriberList.create!(
        child_benefit_base_params.merge(
          slug: "child-benefit-f71e6de312",
          links: {},
          content_id: "cc9eb8ab-7701-43a7-a66d-bdc5046224c0",
        ),
      )
    end

    let!(:tax_credit_good_list) do
      SubscriberList.create!(
        tax_credit_base_params.merge(
          slug: "tax-credits-and-child-benefit-tax-credits",
          links: { "topics" => { "any" => %w[f881f972-6094-4c7d-849c-9143461a9307] } },
          content_id: nil,
        ),
      )
    end

    let!(:tax_credit_bad_list) do
      SubscriberList.create!(
        tax_credit_base_params.merge(
          slug: "tax-credits-c845c124bb",
          links: {},
          content_id: "f881f972-6094-4c7d-849c-9143461a9307",
        ),
      )
    end

    it "will raise an error with invalid prefix arguments" do
      prefix = "foo"
      remover = described_class.new(prefix)
      message = "Subscription migration not possible for the provided prefix"
      expect { remover.process_all_lists }.to raise_error(message)
    end

    it "can can only be called with valid prefix arguments" do
      valid_prefixes = %w[topic organisations]
      valid_prefixes.each do |prefix|
        remover = described_class.new(prefix)
        expect { remover.process_all_lists }.not_to raise_error
      end
    end

    context "when the destination subscriber list has active subscriptions" do
      before do
        create(:subscription, subscriber_list: tax_credit_good_list)
        create(:subscription, subscriber_list: child_benefit_good_list)
        create(:subscription, subscriber_list: tax_credit_bad_list)
        create(:subscription, subscriber_list: child_benefit_bad_list)
      end

      it "calls the SubscriberListMover" do
        remover = described_class.new(prefix)
        list_mover_double = double("SubscriberListMover")
        expect(list_mover_double).to receive(:call).twice
        expect(tax_credit_good_list.active_subscriptions_count).to be 1
        expect(child_benefit_good_list.active_subscriptions_count).to be 1

        allow(SubscriberListMover)
          .to receive(:new)
          .with(from_slug: "tax-credits-c845c124bb", to_slug: "tax-credits-and-child-benefit-tax-credits")
          .and_return(list_mover_double)

        allow(SubscriberListMover)
          .to receive(:new)
          .with(from_slug: "child-benefit-f71e6de312", to_slug: "tax-credits-and-child-benefit-child-benefit")
          .and_return(list_mover_double)

        remover.process_all_lists
      end
    end

    context "when the destination subscriber list has no active subscriptions" do
      it "does not call the SubscriberListMover" do
        remover = described_class.new(prefix)
        list_mover_double = double("SubscriberListMover")

        expect(tax_credit_good_list.active_subscriptions_count).to be 0
        expect(child_benefit_good_list.active_subscriptions_count).to be 0
        expect(list_mover_double).not_to receive(:call)

        remover.process_all_lists
      end
    end

    context "when the bad subscriber_list has no active subscriptions" do
      before do
        create(:subscription, subscriber_list: tax_credit_good_list)
        create(:subscription, subscriber_list: child_benefit_good_list)
      end

      it "does not call the SubscriberListMover" do
        remover = described_class.new(prefix)
        list_mover_double = double("SubscriberListMover")

        expect(list_mover_double).not_to receive(:call)

        remover.process_all_lists

        expect(tax_credit_good_list.active_subscriptions_count).to be 1
        expect(child_benefit_good_list.active_subscriptions_count).to be 1
      end
    end
  end
end

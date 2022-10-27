RSpec.describe MergeSubscribersService do
  let(:user) { create :user }

  describe ".call" do
    let(:subscriber_to_keep) { create(:subscriber) }
    let(:subscriber_to_absorb) { create(:subscriber) }

    it "does not change the subscriptions for subscriber_to_keep" do
      expect { merge_subscribers! }.to_not(change { kept_subscriptions })
    end

    it "nullifies subscriber_to_absorb" do
      merge_subscribers!
      expect(subscriber_to_absorb.reload.address).to be_nil
    end

    context "when subscriber_to_keep has active subscriptions" do
      let!(:active_subscriptions_to_keep) do
        create_list(:subscription, 5, subscriber: subscriber_to_keep)
      end

      it "does not change the subscriptions" do
        expect { merge_subscribers! }.to_not(change { kept_subscriptions })
      end

      context "when subscriber_to_absorb has active subscriptions" do
        let!(:active_subscriptions_to_absorb) do
          create_list(:subscription, 5, subscriber: subscriber_to_absorb)
        end

        it "adds the active subscriptions to subscriber_to_keep" do
          merge_subscribers!
          expect(kept_subscriptions[:active]).to include(*active_subscriptions_to_keep.map { |sub| subscription_hash(sub) })
          expect(kept_subscriptions[:active]).to include(*active_subscriptions_to_absorb.map { |sub| subscription_hash(sub).merge(subscriber_id: subscriber_to_keep.id) })
        end

        it "marks the absorbed active subscriptions as ended" do
          merge_subscribers!
          expect(subscriber_to_absorb.active_subscriptions.count).to be(0)
        end

        context "when both subscribers have a subscription for the same topic" do
          let(:less_frequent_subscription) { active_subscriptions_to_keep[0] }

          let!(:more_frequent_subscription) do
            create(
              :subscription,
              subscriber: subscriber_to_absorb,
              subscriber_list: less_frequent_subscription.subscriber_list,
              frequency: Frequency::DAILY,
            )
          end

          before { less_frequent_subscription.update!(frequency: Frequency::WEEKLY) }

          it "keeps the most frequent" do
            merge_subscribers!
            expect(kept_subscriptions[:active]).to include(subscription_hash(more_frequent_subscription).merge(subscriber_id: subscriber_to_keep.id))
          end
        end
      end

      context "when subscriber_to_absorb has ended subscriptions" do
        let!(:ended_subscriptions_to_absorb) do
          create_list(:subscription, 5, :ended, subscriber: subscriber_to_absorb)
        end

        it "does not change the subscriptions" do
          expect { merge_subscribers! }.not_to(change { kept_subscriptions })
        end
      end
    end

    context "when subscriber_to_keep has ended subscriptions" do
      let!(:ended_subscriptions_to_keep) do
        create_list(:subscription, 5, :ended, subscriber: subscriber_to_keep)
      end

      it "does not change the subscriptions" do
        expect { merge_subscribers! }.to_not(change { kept_subscriptions })
      end

      context "when subscriber_to_absorb has active subscriptions" do
        let!(:active_subscriptions_to_absorb) do
          create_list(:subscription, 5, subscriber: subscriber_to_absorb)
        end

        it "adds the active subscriptions to subscriber_to_keep" do
          merge_subscribers!
          expect(kept_subscriptions[:active]).to contain_exactly(*active_subscriptions_to_absorb.map { |sub| subscription_hash(sub).merge(subscriber_id: subscriber_to_keep.id) })
        end
      end

      context "when subscriber_to_absorb has ended subscriptions" do
        let!(:ended_subscriptions_to_absorb) do
          create_list(:subscription, 5, :ended, subscriber: subscriber_to_absorb)
        end

        it "does not change the subscriptions" do
          expect { merge_subscribers! }.not_to(change { kept_subscriptions })
        end
      end
    end

    context "when subscriber_to_absorb has active subscriptions" do
      let!(:active_subscriptions_to_absorb) do
        create_list(:subscription, 5, subscriber: subscriber_to_absorb)
      end

      it "adds the active subscriptions to subscriber_to_keep" do
        merge_subscribers!
        expect(kept_subscriptions[:active]).to contain_exactly(*active_subscriptions_to_absorb.map { |sub| subscription_hash(sub).merge(subscriber_id: subscriber_to_keep.id) })
      end
    end

    context "when subscriber_to_absorb has ended subscriptions" do
      let!(:ended_subscriptions_to_absorb) do
        create_list(:subscription, 5, :ended, subscriber: subscriber_to_absorb)
      end

      it "does not change the subscriptions" do
        expect { merge_subscribers! }.not_to(change { kept_subscriptions })
      end
    end

    context "when subscriber_to_absorb is not present" do
      let(:subscriber_to_absorb) { nil }

      it "gracefully terminates" do
        merge_subscribers!
      end
    end

    def subscription_hash(subscription)
      subscription.reload
      {
        subscriber_id: subscription.subscriber_id,
        subscriber_list_id: subscription.subscriber_list_id,
        frequency: subscription.frequency,
      }
    end

    def kept_subscriptions
      subscriber_to_keep.reload
      {
        active: subscriber_to_keep.active_subscriptions.map { |sub| subscription_hash(sub) },
        ended: subscriber_to_keep.ended_subscriptions.map { |sub| subscription_hash(sub) },
      }
    end

    def merge_subscribers!
      described_class.call(
        subscriber_to_keep:,
        subscriber_to_absorb:,
        current_user: user,
      )
    end
  end
end

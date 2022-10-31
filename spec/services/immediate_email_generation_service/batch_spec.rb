RSpec.describe ImmediateEmailGenerationService::Batch do
  let(:content) { create(:content_change) }
  let(:subscriptions) { [create(:subscription, :immediately)] }

  let(:instance) do
    described_class.new(content, subscriptions.map(&:id))
  end

  describe "#generate_emails" do
    it "creates emails" do
      expect { instance.generate_emails }
        .to change { Email.count }
        .by(1)
    end

    it "populates subscription_contents" do
      scope = SubscriptionContent.where(content_change: content,
                                        subscription: subscriptions)

      expect { instance.generate_emails }
        .to change { scope.count }
        .by(1)
    end

    it "returns ids of emails created" do
      email_ids = instance.generate_emails
      expect(email_ids).to match_array(Email.last(2).pluck(:id))
    end

    context "when content is a content_change" do
      it "uses ImmediateEmailBuilder to build emails" do
        expect(ImmediateEmailBuilder).to receive(:call)
           .with(content, subscriptions)
           .and_call_original

        instance.generate_emails
      end

      it "sends stats about the generated emails" do
        expect(Metrics).to receive(:content_change_emails)
          .with(content, 1)

        instance.generate_emails
      end
    end

    context "when content is a message" do
      let(:content) { create(:message) }

      it "uses ImmediateEmailBuilder to build emails" do
        expect(ImmediateEmailBuilder).to receive(:call)
           .with(content, subscriptions)
           .and_call_original

        instance.generate_emails
      end
    end

    context "when a subscription was ended after determining which lists to email" do
      let(:subscriptions) { [create(:subscription, :immediately, :ended)] }

      it "doesn't email a subscriber without active subscriptions" do
        expect { instance.generate_emails }
          .not_to(change { Email.count })
      end

      it "only uses active subscriptions to create the email" do
        expect(ImmediateEmailBuilder).to_not receive(:call)
        instance.generate_emails
      end
    end

    context "when one of the specified subscriptions is not immediate" do
      let(:subscriptions) { [create(:subscription, :daily)] }

      it "doesn't use that subscription to create the email" do
        expect(ImmediateEmailBuilder).to_not receive(:call)
        instance.generate_emails
      end

      context "when the content is a message with override_subscription_frequency_to_immediate set to true" do
        let(:content) { create(:message, override_subscription_frequency_to_immediate: true) }

        it "uses ImmediateEmailBuilder to build emails" do
          expect(ImmediateEmailBuilder).to receive(:call)
           .with(content, subscriptions)
           .and_call_original

          instance.generate_emails
        end
      end
    end

    context "when only some of the emails were generated due to a failure" do
      let(:subscription) { create(:subscription, :immediately) }
      let(:other_subscription) { create(:subscription, :immediately) }
      let(:subscriptions) { [subscription, other_subscription] }

      before do
        email = create(:email)
        create(:subscription_content,
               subscription: other_subscription,
               email:,
               content_change: content)
      end

      it "only creates emails that haven't been previously created" do
        expect { instance.generate_emails }
          .to change { Email.where(subscriber_id: subscription.subscriber_id).count }.by(1)
          .and change { Email.where(address: other_subscription.subscriber_id).count }.by(0)
      end
    end

    context "when a previous attempt created all the emails of this batch" do
      before do
        email = create(:email)
        create(:subscription_content,
               subscription: subscriptions.first,
               email:,
               content_change: content)
      end

      it "happily creates no emails" do
        expect { instance.generate_emails }
          .not_to(change { Email.count })
      end
    end
  end
end

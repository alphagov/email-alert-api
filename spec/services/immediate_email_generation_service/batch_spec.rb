RSpec.describe ImmediateEmailGenerationService::Batch do
  let(:content_change) { create(:content_change) }
  let(:message) { create(:message) }
  let(:subscriber1) { create(:subscriber) }
  let(:subscriber2) { create(:subscriber) }

  let(:subscriber1_subscription) do
    create(:subscription, :immediately, subscriber: subscriber1)
  end

  let(:subscriber2_subscription) do
    create(:subscription, :immediately, subscriber: subscriber2)
  end

  let(:subscriptions) do
    [subscriber1_subscription, subscriber2_subscription]
  end

  let(:subscription_ids) { subscriptions.map(&:id) }

  describe "#generate_emails" do
    let(:instance) { described_class.new(content_change, subscription_ids) }

    it "creates emails" do
      expect { instance.generate_emails }
        .to change { Email.count }
        .by(2)
    end

    it "populates subscription_contents" do
      scope = SubscriptionContent.where(content_change: content_change,
                                        subscription_id: subscription_ids)

      expect { instance.generate_emails }
        .to change { scope.count }
        .by(subscription_ids.count)
    end

    it "returns ids of emails created" do
      email_ids = instance.generate_emails
      expect(email_ids).to match_array(Email.last(2).pluck(:id))
    end

    context "when content is a content_change" do
      let(:instance) { described_class.new(content_change, subscription_ids) }

      it "uses ImmediateEmailBuilder to build emails" do
        expect(ImmediateEmailBuilder).to receive(:call)
           .with(content_change, subscriptions)
           .and_call_original

        instance.generate_emails
      end

      it "sends stats about the generated emails" do
        expect(Metrics).to receive(:content_change_emails)
                              .with(content_change, 2)
        instance.generate_emails
      end
    end

    context "when content is a message" do
      let(:instance) { described_class.new(message, subscription_ids) }

      it "uses ImmediateEmailBuilder to build emails" do
        expect(ImmediateEmailBuilder).to receive(:call)
           .with(message, subscriptions)
           .and_call_original

        instance.generate_emails
      end
    end

    context "when a subscription was ended after determining which lists to email" do
      let(:subscriber1_subscription) do
        create(:subscription, :immediately, :ended, subscriber: subscriber1)
      end

      let(:subscriber2_subscription) do
        create(:subscription, :immediately, subscriber: subscriber2)
      end

      it "doesn't email a subscriber without active subscriptions" do
        expect { instance.generate_emails }
          .not_to(change { Email.where(address: subscriber1.address).count })
      end

      it "only uses active subscriptions to create the email" do
        expect(ImmediateEmailBuilder).to receive(:call)
           .with(content_change, [subscriber2_subscription])
           .and_call_original

        instance.generate_emails
      end
    end

    context "when one of the specified subscriptions is not immediate" do
      let(:subscriber1_subscription) do
        create(:subscription, :daily, subscriber: subscriber1)
      end

      let(:subscriber2_subscription) do
        create(:subscription, :immediately, subscriber: subscriber2)
      end

      it "doesn't use that subscription to create the email" do
        expect(ImmediateEmailBuilder).to receive(:call)
           .with(content_change, [subscriber2_subscription])
           .and_call_original

        instance.generate_emails
      end
    end

    context "when a previous attempt to generate emails failed and some of the " \
      "emails were already created" do
      before do
        email = create(:email)

        create(:subscription_content,
               subscription: subscriber1_subscription,
               email: email,
               content_change: content_change)
      end

      it "only creates emails that haven't been previously created" do
        expect { instance.generate_emails }
          .to change { Email.where(address: subscriber2.address).count }.by(1)
          .and change { Email.where(address: subscriber1.address).count }.by(0)
      end
    end

    context "when a previous attempt created all the emails of this batch" do
      before do
        email = create(:email)
        [subscriber1_subscription, subscriber2_subscription].each do |subscription|
          create(:subscription_content,
                 subscription: subscription,
                 email: email,
                 content_change: content_change)
        end
      end

      it "happily creates no emails" do
        expect { instance.generate_emails }
          .not_to(change { Email.count })
      end
    end
  end
end

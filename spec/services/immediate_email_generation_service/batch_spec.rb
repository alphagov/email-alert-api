RSpec.describe ImmediateEmailGenerationService::Batch do
  let(:content_change) { create(:content_change) }
  let(:message) { create(:message) }
  let(:subscriber1) { create(:subscriber) }
  let(:subscriber2) { create(:subscriber) }

  let(:subscriber1_subscriptions) do
    create_list(:subscription, 2, :immediately, subscriber: subscriber1)
  end

  let(:subscriber2_subscriptions) do
    create_list(:subscription, 3, :immediately, subscriber: subscriber2)
  end

  let(:subscription_ids_by_subscriber) do
    {
      subscriber1.id => subscriber1_subscriptions.map(&:id),
      subscriber2.id => subscriber2_subscriptions.map(&:id),
    }
  end

  def email_parameters(content, subscriber, subscriptions)
    {
      address: subscriber.address,
      content_change: (content if content.is_a?(ContentChange)),
      message: (content if content.is_a?(Message)),
      subscriptions: subscriptions,
      subscriber_id: subscriber.id,
    }.compact
  end

  describe "#generate_emails" do
    let(:instance) { described_class.new(content_change, subscription_ids_by_subscriber) }

    it "creates emails" do
      expect { instance.generate_emails }
        .to change { Email.count }
        .by(2)
    end

    it "populates subscription_contents" do
      subscription_ids = subscription_ids_by_subscriber.values.flatten
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
      let(:instance) { described_class.new(content_change, subscription_ids_by_subscriber) }

      it "uses ContentChangeEmailBuilder to build emails" do
        emails_params = [
          email_parameters(content_change, subscriber1, subscriber1_subscriptions),
          email_parameters(content_change, subscriber2, subscriber2_subscriptions),
        ]

        expect(ContentChangeEmailBuilder).to receive(:call)
                                         .with(emails_params)
                                         .and_call_original
        instance.generate_emails
      end

      it "sends stats about the generated emails" do
        expect(Metrics).to receive(:content_change_emails)
                              .with(content_change, 2)
        instance.generate_emails
      end

      it "doesn't use MessageEmailBuilder" do
        expect(MessageEmailBuilder).not_to receive(:call)
        instance.generate_emails
      end
    end

    context "when content is a message" do
      let(:instance) { described_class.new(message, subscription_ids_by_subscriber) }

      it "uses MessageEmailBuilder to build emails" do
        emails_params = [
          email_parameters(message, subscriber1, subscriber1_subscriptions),
          email_parameters(message, subscriber2, subscriber2_subscriptions),
        ]

        expect(MessageEmailBuilder).to receive(:call)
                                   .with(emails_params)
                                   .and_call_original
        instance.generate_emails
      end

      it "doesn't use ContentChangeEmailBuilder" do
        expect(ContentChangeEmailBuilder).not_to receive(:call)
        instance.generate_emails
      end
    end

    context "when a subscription was ended after determining which lists to email" do
      let(:subscriber1_subscriptions) do
        create_list(:subscription, 2, :immediately, :ended, subscriber: subscriber1)
      end

      let(:subscriber2_subscriptions) do
        [
          create(:subscription, :ended, :immediately, subscriber: subscriber2),
          subscriber2_active_subscription,
        ]
      end

      let(:subscriber2_active_subscription) do
        create(:subscription, :immediately, subscriber: subscriber2)
      end

      it "doesn't email a subscriber without active subscriptions" do
        expect { instance.generate_emails }
          .not_to(change { Email.where(address: subscriber1.address).count })
      end

      it "only uses active subscriptions to create the email" do
        email_params = email_parameters(content_change,
                                        subscriber2,
                                        [subscriber2_active_subscription])

        expect(ContentChangeEmailBuilder).to receive(:call)
                                         .with([email_params])
                                         .and_call_original
        instance.generate_emails
      end
    end

    context "when a subscriptions frequency was changed after determining which lists to email" do
      let(:subscriber1_subscriptions) do
        create_list(:subscription, 2, :daily, :ended, subscriber: subscriber1)
      end

      let(:subscriber2_subscriptions) do
        [
          create(:subscription, :weekly, subscriber: subscriber2),
          subscriber2_immediate_subscription,
        ]
      end

      let(:subscriber2_immediate_subscription) do
        create(:subscription, :immediately, subscriber: subscriber2)
      end

      it "doesn't use that subscription to create the email" do
        email_params = email_parameters(content_change,
                                        subscriber2,
                                        [subscriber2_immediate_subscription])

        expect(ContentChangeEmailBuilder).to receive(:call)
                                         .with([email_params])
                                         .and_call_original
        instance.generate_emails
      end
    end

    context "when a previous attempt to generate emails failed and some of the " \
      "emails were already created" do
      before do
        email = create(:email)
        subscriber1_subscriptions.each do |subscription|
          create(:subscription_content,
                 subscription: subscription,
                 email: email,
                 content_change: content_change)
        end
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
        [subscriber1_subscriptions, subscriber2_subscriptions].flatten.each do |subscription|
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

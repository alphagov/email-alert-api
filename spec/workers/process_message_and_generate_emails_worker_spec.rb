RSpec.describe ProcessMessageAndGenerateEmailsWorker do
  let(:message) do
    create(
      :message,
      criteria_rules: [
        { type: "tag", key: "topics", value: "oil-and-gas/licensing" },
      ],
    )
  end

  let(:email) { create(:email) }

  context "with a subscription" do
    let(:subscriber) { create(:subscriber) }
    let(:subscriber_list) { create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } }) }
    let!(:subscription) { create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list) }

    it "creates subscription content for the message" do
      expect { subject.perform(message.id) }
        .to change { SubscriptionContent.count }
        .by(1)
    end

    it "marks the message as processed" do
      expect { subject.perform(message.id) }
        .to change { message.reload.processed? }
        .to(true)
    end

    it "creates a MatchedMessage" do
      expect { subject.perform(message.id) }
        .to change { MatchedMessage.count }.by(1)
    end

    context "when the subscription content has already been imported for the message" do
      before do
        create(
          :subscription_content,
          :with_message,
          message: message,
          subscription: subscription,
        )
      end

      it "doesn't create another subscription content" do
        expect { subject.perform(message.id) }
          .to_not(change { SubscriptionContent.count })
      end
    end
  end

  context "with an already processed message" do
    before { message.mark_processed! }

    it "shouldn't process the message" do
      expect(message).to_not receive(:mark_processed!)
      subject.perform(message.id)
    end
  end

  context "with a courtesy subscription" do
    let!(:subscriber) { create(:subscriber, address: Email::COURTESY_EMAIL) }

    it "creates an email for the courtesy email group" do
      expect(MessageEmailBuilder)
        .to receive(:call)
        .with([hash_including(address: subscriber.address)])
        .and_call_original

      subject.perform(message.id)
    end

    it "enqueues the email to send to the courtesy subscription group" do
      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(kind_of(String), queue: :delivery_immediate)

      subject.perform(message.id)
    end
  end

  context "with subscribers that have duplicate subscription contents" do
    it "deduplicates when creating the emails" do
      subscriber_one = create(:subscriber)
      subscription_one = create(:subscription, subscriber: subscriber_one)
      subscription_two = create(:subscription, subscriber: subscriber_one)
      message = create(:message)

      create(
        :subscription_content,
        subscription: subscription_one,
        message: message,
        content_change: nil,
      )

      create(
        :subscription_content,
        subscription: subscription_two,
        message: message,
        content_change: nil,
      )

      described_class.new.perform(message.id)

      expect(Email.count).to eq(1)
    end
  end

  context "with many subscription contents" do
    before do
      50.times do
        create(:subscription_content, message: message, content_change: nil)
      end
    end

    it "should match up with the right emails" do
      subject.perform(message.id)

      SubscriptionContent.includes(:email, subscription: :subscriber).find_each do |subscription_content|
        expect(subscription_content.email.address)
          .to eq(subscription_content.subscription.subscriber.address)
      end
    end
  end

  context "with a subscription content" do
    let!(:subscription_content) { create(:subscription_content, message: message, content_change: nil) }

    before do
      create(:subscription_content, email: create(:email))
      create(:subscription_content, subscription: create(:subscription, subscriber: create(:subscriber, :nullified)))
    end

    it "should create an email" do
      expect { subject.perform(message.id) }
        .to change { Email.count }
        .by(1)
    end

    it "should associate the subscription content with the email" do
      subject.perform(message.id)
      expect(subscription_content.reload.email).to_not be_nil
    end

    context "with a normal priority message" do
      it "should queue a delivery email job" do
        expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
          .with(an_instance_of(String), queue: :delivery_immediate)

        subject.perform(message.id)
      end
    end

    context "with a high priority message" do
      before do
        subscription_content.message.update(priority: "high")
      end

      it "should queue a delivery email job with a high priority" do
        expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
          .with(an_instance_of(String), queue: :delivery_immediate_high)

        subject.perform(message.id)
      end
    end
  end

  context "with multiple messages" do
    it "will only process subscription contents for the message it is passed" do
      subscriber_one = create(:subscriber)
      subscriber_two = create(:subscriber)
      subscription_one = create(:subscription, subscriber: subscriber_one)
      subscription_two = create(:subscription, subscriber: subscriber_two)
      message_one = create(:message)
      message_two = create(:message)

      subscription_content_one = create(
        :subscription_content,
        subscription: subscription_one,
        message: message_one,
        content_change: nil,
      )

      subscription_content_two = create(
        :subscription_content,
        subscription: subscription_two,
        message: message_two,
        content_change: nil,
      )

      described_class.new.perform(message_one.id)

      expect(Email.count).to eq(1)
      subscription_content_one.reload
      subscription_content_two.reload
      expect(subscription_content_one.email.address).to eq(subscriber_one.address)
      expect(subscription_content_two.email).to be_nil
    end
  end

  context "with multiple jobs for the same content_id running at the same time" do
    let(:subscriber_list) { create(:subscriber_list) }
    let(:subscriptions) { create_list(:subscription, 100, subscriber_list: subscriber_list) }
    let(:matched_message) { create(:matched_message, subscriber_list: subscriber_list) }
    let!(:content_change) { matched_message.message }

    it "will only process each subscription_content once" do
      allow_any_instance_of(ProcessMessageAndGenerateEmailsWorker).to receive(:BATCH_SIZE).and_return(50)
      allow_any_instance_of(ProcessContentChangeAndGenerateEmailsWorker).to receive(:perform_in).and_return(true)

      subscriptions.each do |subscription|
        create(:subscription_content, message: message, content_change: nil, subscription: subscription)
      end

      wait_for_it = true
      threads = 5.times.map do
        Thread.new do
          true while wait_for_it
          begin
            ProcessMessageAndGenerateEmailsWorker.new.perform(message.id)
          rescue ActiveRecord::ActiveRecordError
            # The thread has hit a database contention error.
            # Sidekiq will retry this for us so we don't need to handle it in the worker
            # But if we don't rescue it here it the test will occasionally fail
          end
        end
      end
      wait_for_it = false
      threads.each(&:join)

      expect(Email.count).to eq(100)
      expect(Email.all.pluck(:address).uniq.count).to eq(100)
    end
  end
end

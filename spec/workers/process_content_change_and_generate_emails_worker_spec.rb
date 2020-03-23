RSpec.describe ProcessContentChangeAndGenerateEmailsWorker do
  let(:content_change) { create(:content_change, tags: { topics: { any: ["oil-and-gas/licensing"] } }) }
  let(:email) { create(:email) }

  context "with a subscription" do
    let(:subscriber) { create(:subscriber) }
    let(:subscriber_list) { create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } }) }
    let!(:matched_content_change) { create(:matched_content_change, subscriber_list: subscriber_list, content_change: content_change) }
    let!(:subscription) { create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list) }

    it "creates subscription content for the content change" do
      expect { subject.perform(content_change.id) }
        .to change { SubscriptionContent.count }
        .by(1)
    end

    it "marks the content_change as processed" do
      expect { subject.perform(content_change.id) }
        .to change { content_change.reload.processed? }
        .to(true)
    end

    context "when the subscription content has already been imported" do
      before { create(:subscription_content, content_change: content_change, subscription: subscription) }

      it "doesn't create another subscription content" do
        expect { subject.perform(content_change.id) }
          .to_not(change { SubscriptionContent.count })
      end
    end
  end

  context "with a courtesy subscription" do
    let!(:subscriber) { create(:subscriber, address: Email::COURTESY_EMAIL) }
    let(:content_change_high_priority) { create(:content_change, priority: "high") }

    it "creates an email for the courtesy email group" do
      expect(ContentChangeEmailBuilder)
        .to receive(:call)
        .with([hash_including(address: subscriber.address)])
        .and_call_original

      subject.perform(content_change.id)
    end

    it "enqueues the email to send to the courtesy subscription group" do
      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(kind_of(String), queue: :delivery_immediate)

      subject.perform(content_change.id)
    end

    it "enqueues the email on the delivery_immediate_high queue when the content change is high priority" do
      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(kind_of(String), queue: :delivery_immediate_high)

      subject.perform(content_change_high_priority.id)
    end
  end

  context "with an already processed content change" do
    before { content_change.mark_processed! }

    it "should return immediate" do
      expect(content_change).to_not receive(:mark_processed!)
      subject.perform(content_change.id)
    end
  end

  context "with subscribers that have duplicate subscription contents" do
    it "deduplicates when creating the emails" do
      subscriber_one = create(:subscriber)
      subscription_one = create(:subscription, subscriber: subscriber_one)
      subscription_two = create(:subscription, subscriber: subscriber_one)
      content_change = create(:content_change)

      create(
        :subscription_content,
        subscription: subscription_one,
        content_change: content_change,
      )

      create(
        :subscription_content,
        subscription: subscription_two,
        content_change: content_change,
      )

      subject.perform(content_change.id)

      expect(Email.count).to eq(1)
    end
  end

  context "with many subscription contents" do
    before do
      50.times do
        create(:subscription_content, content_change: content_change)
      end
    end

    it "should match up with the right emails" do
      subject.perform(content_change.id)

      SubscriptionContent.includes(:email, subscription: :subscriber).find_each do |subscription_content|
        expect(subscription_content.email.address)
          .to eq(subscription_content.subscription.subscriber.address)
      end
    end
  end

  context "with a subscription content" do
    let!(:subscription_content) { create(:subscription_content, content_change: content_change) }

    before do
      create(:subscription_content, content_change: content_change, email: create(:email))
      create(:subscription_content, content_change: content_change, subscription: create(:subscription, subscriber: create(:subscriber, :nullified)))
    end

    it "should create an email" do
      expect { subject.perform(content_change.id) }
        .to change { Email.count }
        .by(1)
    end

    it "should associate the subscription content with the email" do
      subject.perform(content_change.id)
      expect(subscription_content.reload.email).to_not be_nil
    end

    context "with a normal priority content change" do
      it "should queue a delivery email job with a normal priority" do
        expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
          .with(an_instance_of(String), queue: :delivery_immediate)

        subject.perform(content_change.id)
      end
    end

    context "with a high priority content change" do
      before do
        subscription_content.content_change.update(priority: "high")
      end

      it "should queue a delivery email job with a high priority" do
        expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
          .with(an_instance_of(String), queue: :delivery_immediate_high)

        subject.perform(content_change.id)
      end
    end
  end

  context "with multiple content changes" do
    it "will only process subscription contents for the content change it is passed" do
      subscriber_one = create(:subscriber)
      subscriber_two = create(:subscriber)
      subscription_one = create(:subscription, subscriber: subscriber_one)
      subscription_two = create(:subscription, subscriber: subscriber_two)
      content_change_one = create(:content_change)
      content_change_two = create(:content_change)

      subscription_content_one = create(
        :subscription_content,
        subscription: subscription_one,
        content_change: content_change_one,
      )

      subscription_content_two = create(
        :subscription_content,
        subscription: subscription_two,
        content_change: content_change_two,
      )

      subject.perform(content_change_one.id)

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
    let(:matched_content_change) { create(:matched_content_change, subscriber_list: subscriber_list) }
    let!(:content_change) { matched_content_change.content_change }

    it "will only process each subscription_content once", testing_transactions: true do
      allow_any_instance_of(ProcessContentChangeAndGenerateEmailsWorker).to receive(:BATCH_SIZE).and_return(50)
      allow_any_instance_of(ProcessContentChangeAndGenerateEmailsWorker).to receive(:perform_in).and_return(true)

      subscriptions.each do |subscription|
        create(:subscription_content, content_change: content_change, subscription: subscription)
      end

      wait_for_it = true
      threads = 10.times.map do
        Thread.new do
          true while wait_for_it
          # rubocop:disable Lint/SuppressedException
          begin
            ProcessContentChangeAndGenerateEmailsWorker.new.perform(content_change.id)
          rescue ActiveRecord::ActiveRecordError
            # The thread has hit a database contention error.
            # Sidekiq will retry this for us so we don't need to handle it in the worker
            # But if we don't rescue it here it the test will occasionally fail
          end
          # rubocop:enable Lint/SuppressedException
        end
      end
      wait_for_it = false
      threads.each(&:join)

      expect(Email.count).to eq(100)
      expect(Email.all.pluck(:address).uniq.count).to eq(100)
    end
  end
end

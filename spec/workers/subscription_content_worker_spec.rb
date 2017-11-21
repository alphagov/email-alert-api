require "rails_helper"

RSpec.describe SubscriptionContentWorker do
  let(:content_change) { FactoryGirl.create(:content_change, tags: { topics: ["oil-and-gas/licensing"] }) }
  let(:email) { FactoryGirl.create(:email) }

  before do
    allow(ContentChange).to receive(:find).with(content_change.id).and_return(content_change)
  end

  context "with a subscription" do
    let(:subscriber) { FactoryGirl.create(:subscriber) }
    let(:subscriber_list) { FactoryGirl.create(:subscriber_list, tags: { topics: ["oil-and-gas/licensing"] }) }
    let!(:subscription) { FactoryGirl.create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list) }

    context "asynchronously" do
      it "should create an email" do
        Sidekiq::Testing.fake! do
          SubscriptionContentWorker.perform_async(content_change_id: content_change.id, priority: :low)

          expect(Email)
            .to receive(:create_from_params!)
            .with(hash_including(title: content_change.title))

          described_class.drain
        end
      end
    end

    context "when we error" do
      def swallow_errors
        expect(Raven)
          .to receive(:capture_exception)
          .with(
            instance_of(ActiveRecord::RecordInvalid),
            tags: { version: 2 }
          )

        expect {
          subject.perform(content_change_id: content_change.id, priority: :low)
        }.not_to raise_error
      end

      it "reports errors when creating a SubscriptionContent in the database to Sentry and swallows them" do
        allow(SubscriptionContent)
          .to receive(:create!)
          .and_raise(ActiveRecord::RecordInvalid)

        swallow_errors
      end

      it "reports errors when creating an Email in the database to Sentry and swallows them" do
        allow(Email)
          .to receive(:create_from_params!)
          .and_raise(ActiveRecord::RecordInvalid)

        swallow_errors
      end
    end

    it "creates subscription content for the content change" do
      expect(SubscriptionContent)
        .to receive(:create!)
        .with(content_change: content_change, subscription: subscription)

      subject.perform(content_change_id: content_change.id, priority: :low)
    end

    it "creates an email with a title of the content change" do
      expect(Email)
        .to receive(:create_from_params!)
        .with(hash_including(title: content_change.title))
        .and_return(email)

      subject.perform(content_change_id: content_change.id, priority: :low)
    end

    it "creates an email to send to the subscriber in the list" do
      expect(Email)
        .to receive(:create_from_params!)
        .with(hash_including(address: subscriber.address))
        .and_return(email)

      subject.perform(content_change_id: content_change.id, priority: :low)
    end

    it "enqueues the email to send to the subscriber" do
      expect(DeliverEmailWorker).to receive(:perform_async_with_priority).with(
        kind_of(Integer), priority: :low,
      )

      subject.perform(content_change_id: content_change.id, priority: :low)
    end

    it "does not enqueue an email to subscribers without a subscription to this content" do
      FactoryGirl.create(:subscriber, address: "should_not_receive_email@example.com")

      expect(DeliverEmailWorker).to receive(:perform_async_with_priority).once

      subject.perform(content_change_id: content_change.id, priority: :low)
    end

    it "enqueues an email with the injected priority" do
      expect(DeliverEmailWorker)
        .to receive(:perform_async_with_priority)
        .with(kind_of(Integer), priority: :high)

      subject.perform(content_change_id: content_change.id, priority: :high)
    end
  end

  context "with a courtesy subscription" do
    let!(:subscriber) { FactoryGirl.create(:subscriber, address: "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk") }

    it "creates an email for the courtesy email group" do
      expect(Email)
        .to receive(:create_from_params!)
        .with(hash_including(address: "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk"))
        .and_return(email)

      subject.perform(content_change_id: content_change.id, priority: :low)
    end

    it "enqueues the email to send to the courtesy subscription group" do
      expect(DeliverEmailWorker)
        .to receive(:perform_async_with_priority)
        .with(kind_of(Integer), priority: :low)

      subject.perform(content_change_id: content_change.id, priority: :low)
    end
  end
end

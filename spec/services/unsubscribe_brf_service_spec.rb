RSpec.describe UnsubscribeBRFService do
  before :each do
    create(
      :subscriber,
      address: Email::COURTESY_EMAIL,
    )
  end

  def create_brf_subscriber_list(address: "test@example.com")
    create_subscriber_list(title: "Find Brexit guidance for your business in the following", address: address)
  end

  def create_non_brf_subscriber_list
    create_subscriber_list(title: "Something else")
  end

  def create_subscriber_list(
    links: {},
        tags: {},
        title: "First Subscription",
        address: "test@example.com"
      )
    subscriber = create(
      :subscriber,
      address: address,
    )
    subscriber_list = create(
      :subscriber_list,
      links: links,
      tags: tags,
      title: title,
    )
    create(
      :subscription,
      subscriber: subscriber,
      subscriber_list: subscriber_list,
    )
    subscriber_list
  end

  shared_examples_for "it_does_not_send_an_email" do
    it "it does not create an email" do
      expect { described_class.call }.to_not(change { Email.count })
    end
    it "does not send emails" do
      expect(DeliveryRequestService).to receive(:call).never
    end
  end

  describe ".call" do
    context "No subscriber lists are found" do
      it_behaves_like "it_does_not_send_an_email"
    end

    context "All subscriptions are ended" do
      before :each do
        subscriber_list = create_brf_subscriber_list
        subscriber_list.subscriptions.each do |subscription|
          subscription.end(reason: :unpublished)
        end
      end
      it_behaves_like "it_does_not_send_an_email"
    end

    context "A BFR subscriber list exists" do
      before :each do
        @subscriber_list = create_brf_subscriber_list
      end
      it "creates an email and a courtesy email" do
        expect { described_class.call }.to change { Email.count }.by(2)
      end
      it "contains the message in the body" do
        expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: eq(UnsubscribeBRFService::MESSAGE))).twice
        described_class.call
      end
      it "contains the correct subject" do
        expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(subject: eq(UnsubscribeBRFService::SUBJECT))).twice
        described_class.call
      end
      it "unsubscribes all subscriptions" do
        described_class.call
        expect(@subscriber_list.subscriptions.map(&:ended_at)).to all(be_truthy)
      end
      it "deactivates subscribers without subscriptions" do
        described_class.call
        expect(@subscriber_list.subscribers.map(&:deactivated_at)).to all(be_present)
      end
    end

    context "There are subscriber lists but no BRF ones" do
      before :each do
        create_non_brf_subscriber_list
      end
      it_behaves_like "it_does_not_send_an_email"
    end

    context "with multiple subscriber lists" do
      before :each do
        @first_subscriber_list = create_brf_subscriber_list(address: "first@test.com")
        @second_subscriber_list = create_brf_subscriber_list(address: "second@test.com")
      end

      it "correctly associates emails with subscriptions" do
        described_class.call
        Subscription.all.each do |subscription|
          email = Email.find(subscription.ended_email_id)
          expect(email.address).to eq(subscription.subscriber.address)
        end
      end
    end

    context "One subscriber, multiple subscriber_lists" do
      before :each do
        subscriber_list1 = create(:subscriber_list, title:  "Find Brexit guidance for your business in the following")
        subscriber_list2 = create(:subscriber_list, title:  "Find Brexit guidance for your business in the following")
        @subscriber = create(:subscriber)
        create(:subscription, subscriber: @subscriber, subscriber_list: subscriber_list1)
        create(:subscription, subscriber: @subscriber, subscriber_list: subscriber_list2)
      end
      it "sends two emails, one to the subscriber, one courtesy" do
        expect { described_class.call }.to change { Email.count }.by(2)
      end
      it "correctly associates deactivated subscriptions with the the email" do
        described_class.call
        expect(Subscription.first.ended_email_id).to eq Subscription.second.ended_email_id
        Email.find(Subscription.first.ended_email_id).address = @subscriber.address
      end
    end
  end
end

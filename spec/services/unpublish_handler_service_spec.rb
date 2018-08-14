RSpec.describe UnpublishHandlerService do
  before :each do
    create(
      :subscriber,
      address: Email::COURTESY_EMAIL,
    )
    @content_id = SecureRandom.uuid
  end

  describe '.call' do
    context 'No subscriber lists are found' do
      it 'it does not create an email' do
        expect { described_class.call(@content_id) }.to_not(change { Email.count })
      end
      it 'does not send emails' do
        expect(DeliveryRequestService).to receive(:call).never
      end
    end

    context 'there is a taxon_tree subscriber list' do
      before :each do
        subscriber = create(
          :subscriber,
          address: 'test@example.com',
          id: 111
        )
        @subscriber_list = create(
          :subscriber_list,
          links: { taxon_tree: [@content_id] },
          title: 'First Subscription',
          )
        create(
          :subscription,
          subscriber: subscriber,
          subscriber_list: @subscriber_list
        )
      end
      it 'creates an email and a courtesy email' do
        expect { described_class.call(@content_id) }.to change { Email.count }.by(2)
      end
      it 'sends the email and a courtesy email to the DeliverRequestWorker' do
        expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(subject: 'First Subscription',
                                        address: 'test@example.com'))
        expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(subject: 'First Subscription',
                                       address: Email::COURTESY_EMAIL))
        described_class.call(@content_id)
      end
      it 'unsubscribes all subscribers' do
        described_class.call(@content_id)
        expect(@subscriber_list.subscriptions.map(&:ended_at)).to all(be_truthy)
      end
      it 'Logs the taxon unpublishing email and the courtesy email' do
        expect(Rails.logger).to receive(:info).with(include('Created Email', 'First Subscription')).twice
        described_class.call(@content_id)
      end

      context 'The subscriber is deactivated' do
        before :each do
          @subscriber_list.subscribers.each(&:deactivate!)
        end
        it 'it does not create an email' do
          expect { described_class.call(@content_id) }.to_not(change { Email.count })
        end
        it 'does not send emails' do
          expect(DeliveryRequestService).to receive(:call).never
        end
      end
    end

    context 'there is a non-taxon subscriber list' do
      before :each do
        subscriber = create(
          :subscriber,
          address: 'test@example.com',
          id: 111
        )
        subscriber_list = create(
          :subscriber_list,
          links: { 'world_locations' => [SecureRandom.uuid, SecureRandom.uuid],
                   'policy_areas' => [@content_id] },
          title: 'First Subscription',
        )
        create(
          :subscription,
          subscriber: subscriber,
          subscriber_list: subscriber_list
        )
      end

      it 'Does not create an email' do
        expect { described_class.call(@content_id) }.to_not(change { Email.count })
      end
      it 'does not send emails' do
        expect(DeliveryRequestService).to receive(:call).never
      end
      it 'Logs the non taxon unpublishing event' do
        expect(Rails.logger).to receive(:info).
          with(include('Not sending notification', 'First Subscription'))
        described_class.call(@content_id)
      end
    end
  end
end

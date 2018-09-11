RSpec.describe UnpublishHandlerService do
  before :each do
    create(
      :subscriber,
      address: Email::COURTESY_EMAIL,
    )
    @content_id = SecureRandom.uuid
    @redirect = double(ContentItem, path: 'to/somewhere', title: 'redirect_title', url: 'http://host/to/somewhere')
  end

  def create_subscriber_list(
        links: {},
        tags: {},
        title: 'First Subscription',
        address: 'test@example.com'
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
      subscriber_list: subscriber_list
    )
    subscriber_list
  end

  shared_examples_for 'it_sends_an_email_with_body_including' do |body|
    it 'creates an email and a courtesy email' do
      expect { described_class.call(@content_id, @redirect) }.to change { Email.count }.by(2)
    end
    it 'uses the redirection in the body of the email' do
      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include(@redirect.url, @redirect.title))).twice
      described_class.call(@content_id, @redirect)
    end
    it 'sends the email and a courtesy email to the DeliverRequestWorker' do
      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(subject: 'GOV.UK update – First Subscription',
                                        address: 'test@example.com'))
      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(subject: 'GOV.UK update – First Subscription',
                                        address: Email::COURTESY_EMAIL))
      described_class.call(@content_id, @redirect)
    end
    it 'sends an email with some specified text' do
      expect(DeliveryRequestService).to receive(:call).
          with(email: having_attributes(body: include(body))).twice
      described_class.call(@content_id, @redirect)
    end
  end

  shared_examples_for 'it_does_not_send_an_email' do
    it 'it does not create an email' do
      expect { described_class.call(@content_id, @redirect) }.to_not(change { Email.count })
    end
    it 'does not send emails' do
      expect(DeliveryRequestService).to receive(:call).never
    end
  end

  shared_examples_for 'it_unsubscribes_all_subscribers' do
    it 'unsubscribes all subscribers' do
      described_class.call(@content_id, @redirect)
      expect(@subscriber_list.subscriptions.map(&:ended_at)).to all(be_truthy)
    end
  end

  describe '.call' do
    context 'No subscriber lists are found' do
      it_behaves_like 'it_does_not_send_an_email'
    end

    context 'All subscriptions are ended' do
      before :each do
        @subscriber_list = create_subscriber_list(links: { taxon_tree: [@content_id] })
        @subscriber_list.subscriptions.each do |subscription|
          subscription.end(reason: :unpublished)
        end
      end
      it_behaves_like 'it_does_not_send_an_email'
    end

    context 'there is a taxon_tree subscriber list' do
      before :each do
        @subscriber_list = create_subscriber_list(links: { taxon_tree: [@content_id] })
      end
      it_behaves_like 'it_sends_an_email_with_body_including', 'has ended because this topic no longer exists on GOV.UK'
      it_behaves_like 'it_unsubscribes_all_subscribers'
    end

    context 'there is a policy area subscriber list' do
      before :each do
        @subscriber_list = create_subscriber_list(links: { policy_areas: [@content_id] })
      end
      it_behaves_like 'it_sends_an_email_with_body_including',
                      "email updates about 'First Subscription"
      it_behaves_like 'it_unsubscribes_all_subscribers'
    end

    context 'there is a policy subscriber list' do
      before :each do
        @subscriber_list = create_subscriber_list(links: { policies: [@content_id] })
      end
      it_behaves_like 'it_sends_an_email_with_body_including',
                      "email updates about 'First Subscription"
      it_behaves_like 'it_unsubscribes_all_subscribers'
    end

    context 'there is a non-taxon subscriber list' do
      before :each do
        create_subscriber_list(links: {
            'world_locations' => [SecureRandom.uuid, SecureRandom.uuid],
            'another' => [@content_id]
        })
      end
      it_behaves_like 'it_does_not_send_an_email'
    end

    context 'with multiple subscriber lists' do
      before :each do
        @first_subscriber_list = create_subscriber_list(
          links: {
            taxon_tree: [@content_id],
            world_locations: [SecureRandom.uuid]
          },
          title: 'First Subscriber List',
          address: 'test1@example.com'
        )
        @second_subscriber_list = create_subscriber_list(
          links: {
            taxon_tree: [@content_id],
            world_locations: [SecureRandom.uuid]
          },
          title: 'Second Subscriber List',
          address: 'test2@example.com'
        )
      end

      it 'correctly associates emails to subscriptions' do
        described_class.call(@content_id, @redirect)

        Subscription.all.each do |subscription|
          email = Email.find(subscription.ended_email_id)

          expect(email.address).to eq(subscription.subscriber.address)
        end
      end
    end
  end
end

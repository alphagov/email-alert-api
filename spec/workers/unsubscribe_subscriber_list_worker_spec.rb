RSpec.describe UnsubscribeSubscriberListWorker do
  describe '.perform' do
    it 'calls the unsubscribe service' do
      list = create(:subscriber_list)
      expect(UnsubscribeService).to receive(:subscriber_list!).with(list, 'unpublished')
      UnsubscribeSubscriberListWorker.perform_async(list.id, :unpublished)
    end
  end
end

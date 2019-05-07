RSpec.describe RemoveCpsService do
  let(:tags) { { a: { any: %w[b] } } }
  let(:content_purpose_supergroup) { 'news_and_communications' }
  let(:updated_tags) { tags.merge(content_purpose_supergroup: { any: [content_purpose_supergroup] }) }

  describe '#deactivate_subscriber_lists' do
    it 'does not create a new SubscriberList because it does not contain a CPS' do
      subscriber_list = FactoryBot.create(:subscriber_list)
      expect { RemoveCpsService.new.deactivate_subscriber_lists }.to_not(change { subscriber_list.reload.attributes })
    end
    it 'removes the CPS from the subscriber list' do
      subscriber_list = FactoryBot.create(:subscriber_list, content_purpose_supergroup: content_purpose_supergroup)
      RemoveCpsService.new.deactivate_subscriber_lists
      subscriber_list.reload
      expect(subscriber_list.content_purpose_supergroup).to be nil
    end
    it 'adds the content purpose supergroup to the tags' do
      subscriber_list = FactoryBot.create(:subscriber_list, tags: tags, content_purpose_supergroup: content_purpose_supergroup)
      RemoveCpsService.new.deactivate_subscriber_lists
      subscriber_list.reload
      expect(subscriber_list.tags).to include(content_purpose_supergroup: { any: [content_purpose_supergroup] })
      expect(subscriber_list.tags).to include(tags)
    end
    context 'A duplicate subscriber list exists' do
      before :each do
        @subscriber_list = FactoryBot.create(:subscriber_list_with_subscribers,
                                             tags: tags,
                                             content_purpose_supergroup: content_purpose_supergroup,
                                             subscriber_count: 2)
        @duplicate_subscriber_list = FactoryBot.create(:subscriber_list, tags: updated_tags, content_purpose_supergroup: nil)
      end
      it 'adds the subscriptions to the duplicate' do
        expect { RemoveCpsService.new.deactivate_subscriber_lists }.to change {
          @duplicate_subscriber_list.reload.subscribers.count
        }.from(0).to(2)
      end

      it 'moves deactivated subscriptions' do
        @subscription = FactoryBot.create(:subscription, :ended, subscriber_list: @subscriber_list)
        expect { RemoveCpsService.new.deactivate_subscriber_lists }.to change {
          @duplicate_subscriber_list.reload.subscribers.count
        }.from(0).to(3)
      end

      context 'there are duplicate subscribers' do
        before :each do
          duplicate_subscriber = FactoryBot.create(:subscriber)
          @subscription = FactoryBot.create(:subscription, subscriber_list: @subscriber_list, subscriber: duplicate_subscriber)
          @duplicate_subscription = FactoryBot.create(:subscription, subscriber_list: @duplicate_subscriber_list, subscriber: duplicate_subscriber)
        end
        it 'deactivates the subscription that is moved' do
          RemoveCpsService.new.deactivate_subscriber_lists
          expect(@subscription.reload.active?).to be false
        end
      end
    end
  end

  describe '#delete_subscriber_lists' do
    context 'there are subscriptions attached to a subscriber list' do
      before :each do
        @subscriber_list = FactoryBot.create(:subscriber_list_with_subscribers,
                                             tags: tags,
                                             content_purpose_supergroup: content_purpose_supergroup,
                                             subscriber_count: 2)
      end
      it 'raises an error' do
        expect {
          RemoveCpsService.new.delete_subscriber_lists
        }.to raise_error(StandardError)
      end
    end
    context 'A duplicate subscriber list exists' do
      before :each do
        @subscriber_list = FactoryBot.create(:subscriber_list,
                                             tags: tags,
                                             content_purpose_supergroup: content_purpose_supergroup)
        @duplicate_subscriber_list = FactoryBot.create(:subscriber_list, tags: updated_tags, content_purpose_supergroup: nil)
      end
      it 'deletes the list' do
        subscriber_list_id = @subscriber_list.id
        RemoveCpsService.new.delete_subscriber_lists
        expect(SubscriberList.exists?(subscriber_list_id)).to be false
      end
      describe 'Move MatchedContentChanges' do
        before :each do
          @content_changes = FactoryBot.create_list(:matched_content_change, 5, subscriber_list: @subscriber_list)
        end
        it 'moves the matched content change to the duplicate list' do
          RemoveCpsService.new.delete_subscriber_lists
          @content_changes.each(&:reload)
          expect(@content_changes.map(&:subscriber_list)).to all eq(@duplicate_subscriber_list)
        end
        context 'there is a duplicate content change' do
          before :each do
            duplicated_content_change = @content_changes.first
            @duplicated_content_change_id = @content_changes.first.id

            FactoryBot.create(:matched_content_change,
                              subscriber_list: @duplicate_subscriber_list,
                              content_change_id: duplicated_content_change.content_change_id)
          end
          it 'does not raise an error' do
            expect { RemoveCpsService.new.delete_subscriber_lists }.to_not raise_error
          end
          it 'destroys the duplicate' do
            RemoveCpsService.new.delete_subscriber_lists
            expect(MatchedContentChange.exists?(@duplicate_content_change_id)).to be false
          end
        end
      end
    end
  end
end

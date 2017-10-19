require 'rails_helper'
require 'data_hygiene/title_fetcher'

RSpec.describe DataHygiene::TitleFetcher do
  let(:client) { double('GovDelivery::Client') }
  let(:logger) { double(:logger, info: true, warn: true) }
  subject { described_class.new(client: client, logger: logger) }

  describe '#update_title' do
    context "when we don't have a name from GovDelivery" do
      let!(:subscriber_list) { create(:subscriber_list, gov_delivery_id: 'ABC_123', title: nil) }

      it 'does not update the subscriber list' do
        expect { subject.send(:update_title, subscriber_list, nil) }
          .to_not change(subscriber_list, :title)

        expect { subject.send(:update_title, subscriber_list, '') }
          .to_not change(subscriber_list, :title)

        expect(subject.stats).to eq(not_found: 2)
      end
    end

    context 'when we have found a name from GovDelivery' do
      context "when the subscriber list's title is missing" do
        shared_examples 'updates the title' do |initial_title|
          let(:new_title) { 'Education' }
          let!(:subscriber_list) { create(:subscriber_list, gov_delivery_id: 'ABC_123', title: initial_title) }

          it "updates the subscriber list's title" do
            expect { subject.send(:update_title, subscriber_list, new_title) }
              .to change { subscriber_list.title }
              .from(initial_title)
              .to(new_title)
          end

          it 'logs the change' do
            expect(logger).to receive(:info).with("ABC_123: title updated to match GovDelivery topic")
            subject.send(:update_title, subscriber_list, new_title)
            expect(subject.stats).to eq(updated: 1)
          end
        end

        it_behaves_like 'updates the title', nil
        it_behaves_like 'updates the title', ''

        context 'when saving fails' do
          let!(:subscriber_list) { create(:subscriber_list, gov_delivery_id: 'ABC_123', title: nil) }
          before do
            allow(subscriber_list).to receive(:save).and_return(false)
          end

          it 'logs the failure' do
            expect(logger).to receive(:warn).with("ABC_123: failed to update title")
            subject.send(:update_title, subscriber_list, 'Education')
            expect(subject.stats).to eq(update_failed: 1)
          end
        end
      end

      context 'when the subscriber list has the same title already' do
        let(:title) { 'Education' }
        let!(:subscriber_list) { create(:subscriber_list, gov_delivery_id: 'ABC_123', title: title) }

        it "doesn't change the title" do
          expect { subject.send(:update_title, subscriber_list, title) }
            .not_to change(subscriber_list, :title)
        end

        it 'logs it' do
          expect(logger).to receive(:info).with("ABC_123: already has matching title")
          subject.send(:update_title, subscriber_list, title)
          expect(subject.stats).to eq(already_matching: 1)
        end
      end

      context 'when the subscriber list has a different title already' do
        let(:new_title) { 'Education' }
        let!(:subscriber_list) { create(:subscriber_list, gov_delivery_id: 'ABC_123', title: 'Space') }

        it "doesn't change the title" do
          expect { subject.send(:update_title, subscriber_list, new_title) }
            .not_to change(subscriber_list, :title)
        end

        it 'logs it' do
          expect(logger)
            .to receive(:warn)
            .with("ABC_123: has GD name Education but EEA title Space; not overwriting existing title with name")
          subject.send(:update_title, subscriber_list, new_title)
          expect(subject.stats).to eq(different: 1)
        end
      end
    end
  end

  describe '#fetch_all_topics' do
    before do
      topics = [
        { 'code' => 'ABC_123', 'name' => 'Education' },
        { 'code' => 'XYZ_789', 'name' => 'Space' },
      ]
      allow(client).to receive(:fetch_topics)
        .and_return('topics' => topics)
    end

    it 'calls the API' do
      expect(client).to receive(:fetch_topics).exactly(1).times
      subject.send(:fetch_all_topics)
    end

    it 'returns a hash mapping topic codes to names' do
      expected_hash = {
        'ABC_123' => 'Education',
        'XYZ_789' => 'Space',
      }
      expect(subject.send(:fetch_all_topics)).to eq(expected_hash)
    end
  end

  describe '#run' do
    let!(:missing_title_list) { create(:subscriber_list, title: nil) }
    let!(:matching_title_list) { create(:subscriber_list, title: 'Education') }
    let!(:different_title_list) { create(:subscriber_list, title: 'Space') }
    let!(:not_on_govdelivery_list) { create(:subscriber_list, title: nil) }
    let!(:empty_govdelivery_name_list) { create(:subscriber_list, title: nil) }

    before do
      topics = [
        { 'code' => missing_title_list.gov_delivery_id, 'name' => 'I have a name' },
        { 'code' => matching_title_list.gov_delivery_id, 'name' => 'Education' },
        { 'code' => different_title_list.gov_delivery_id, 'name' => 'Something else' },
        { 'code' => empty_govdelivery_name_list.gov_delivery_id, 'name' => '' },
      ]
      allow(client).to receive(:fetch_topics)
        .and_return('topics' => topics)
    end

    it 'fetches the topics from GovDelivery only once' do
      expect(client).to receive(:fetch_topics).exactly(1).times
      subject.run
    end

    it 'adds the title to the list which was missing one' do
      subject.run
      missing_title_list.reload
      expect(missing_title_list.title).to eq('I have a name')
    end

    it 'does not update the other lists' do
      [
        matching_title_list,
        different_title_list,
        not_on_govdelivery_list,
        empty_govdelivery_name_list
      ].each(&:reload)

      expect(matching_title_list.title).to eq('Education')
      expect(different_title_list.title).to eq('Space')
      expect(not_on_govdelivery_list.title).to eq(nil)
      expect(empty_govdelivery_name_list.title).to eq(nil)
    end

    it 'logs everything at the appropriate level' do
      [
        "Fetching all topics from GovDelivery...",
        "4 topics found on GovDelivery",
        "Updating titles for 5 subscriber lists",
        "#{missing_title_list.gov_delivery_id}: title updated to match GovDelivery topic",
        "#{matching_title_list.gov_delivery_id}: already has matching title",
        "",
        "Done:",
        "  updated: 1",
        "  already_matching: 1",
        "  different: 1",
        "  not_found: 2",
      ].each do |message|
        expect(logger).to receive(:info).with(message)
      end

      [
        "#{different_title_list.gov_delivery_id}: has GD name Something else but EEA title Space; not overwriting existing title with name",
        "#{not_on_govdelivery_list.gov_delivery_id}: no name found for topic from GovDelivery",
        "#{empty_govdelivery_name_list.gov_delivery_id}: no name found for topic from GovDelivery"
      ].each do |message|
        expect(logger).to receive(:warn).with(message)
      end

      subject.run
    end

    context "we can't fetch the topics from GovDelivery" do
      class GovDeliveryTimeout < StandardError; end

      before do
        allow(client).to receive(:fetch_topics).and_raise(GovDeliveryTimeout)
      end

      it 'explodes' do
        # If we can't fetch the topics then we can't do anything else useful, so
        # there's no point in catching the error
        expect { subject.run }.to raise_error(GovDeliveryTimeout)
      end
    end
  end
end

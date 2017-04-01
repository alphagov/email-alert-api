require 'rails_helper'
require 'data_hygiene/title_fetcher'

RSpec.describe DataHygiene::TitleFetcher do
  let(:client) { double('GovDelivery::Client') }
  let(:logger) { double(:logger, info: true, warn: true) }
  subject { described_class.new(client: client, logger: logger) }

  describe '#fetch_topic_title' do
    let(:gov_delivery_id) { 'ID_1' }

    context 'when the topic exists on GovDelivery' do
      before do
        allow(client).to receive(:fetch_topic)
          .and_return(double(name: 'Education'))
      end

      it 'returns the name from the GovDelivery response' do
        expect(subject.send(:fetch_topic_title, gov_delivery_id)).to eq('Education')
      end
    end

    context 'when the topic does not exist on GovDelivery' do
      before do
        allow(client).to receive(:fetch_topic)
          .and_raise(GovDelivery::Client::TopicNotFound)
      end

      it 'logs the error' do
        expect(logger).to receive(:warn).with("ID_1: topic not found on GovDelivery")
        subject.send(:fetch_topic_title, gov_delivery_id)
        expect(subject.stats).to eq({ not_found: 1 })
      end
    end

    context '#when the GovDelivery `fetch_topic` endpoint has an error' do
      before do
        allow(client).to receive(:fetch_topic)
          .and_raise(GovDelivery::Client::UnknownError.new("Error message"))
      end

      it 'logs the error' do
        expect(logger).to receive(:warn).with("ID_1: error fetching topic from GovDelivery: Error message")
        subject.send(:fetch_topic_title, gov_delivery_id)
        expect(subject.stats).to eq({ error_fetching: 1 })
      end
    end
  end

  describe '#update_title' do
    let!(:subscriber_list) { create(:subscriber_list, gov_delivery_id: 'ABC_123', title: nil) }

    context 'when the topic exists on GovDelivery' do
      before do
        allow(client).to receive(:fetch_topic)
          .and_return(double(name: 'Education'))
      end

      context "when the subscriber list's title is missing" do
        shared_examples 'updates the title' do |initial_title|
          let!(:subscriber_list) { create(:subscriber_list, gov_delivery_id: 'ABC_123', title: initial_title) }

          it "updates the subscriber list's title" do
            expect { subject.send(:update_title, subscriber_list) }
              .to change { subscriber_list.title }
              .from(initial_title)
              .to('Education')
          end

          it 'logs the change' do
            expect(logger).to receive(:info).with("ABC_123: title updated to match GovDelivery topic")
            subject.send(:update_title, subscriber_list)
            expect(subject.stats).to eq({ updated: 1 })
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
            subject.send(:update_title, subscriber_list)
            expect(subject.stats).to eq({ update_failed: 1 })
          end
        end
      end

      context 'when the subscriber list has the same title already' do
        let!(:subscriber_list) { create(:subscriber_list, gov_delivery_id: 'ABC_123', title: 'Education') }

        it "doesn't change the title" do
          expect { subject.send(:update_title, subscriber_list) }
            .not_to change { subscriber_list.title }
        end

        it 'logs it' do
          expect(logger).to receive(:info).with("ABC_123: already has matching title")
          subject.send(:update_title, subscriber_list)
          expect(subject.stats).to eq({ already_matching: 1 })
        end
      end

      context 'when the subscriber list has a different title already' do
        let!(:subscriber_list) { create(:subscriber_list, gov_delivery_id: 'ABC_123', title: 'Space') }

        it "doesn't change the title" do
          expect { subject.send(:update_title, subscriber_list) }
            .not_to change { subscriber_list.title }
        end

        it 'logs it' do
          expect(logger)
            .to receive(:warn)
            .with("ABC_123: has GD name Education but EEA title Space; not overwriting existing title with name")
          subject.send(:update_title, subscriber_list)
          expect(subject.stats).to eq({ different: 1 })
        end
      end
    end

    context 'when the topic does not exist on GovDelivery' do
      before do
        allow(client).to receive(:fetch_topic)
          .and_raise(GovDelivery::Client::TopicNotFound)
      end

      it 'does not update the subscriber list' do
        expect { subject.send(:update_title, subscriber_list) }.to_not change { subscriber_list.title }
      end
    end

    context '#when the GovDelivery `fetch_topic` endpoint has an error' do
      before do
        allow(client).to receive(:fetch_topic)
          .and_raise(GovDelivery::Client::UnknownError.new("Error message"))
      end

      it 'does not update the subscriber list' do
        expect { subject.send(:update_title, subscriber_list) }.to_not change { subscriber_list.title }
      end
    end
  end

  describe '#run' do
    let!(:missing_title_list) { create(:subscriber_list, title: nil) }
    let!(:matching_title_list) { create(:subscriber_list, title: 'Education') }
    let!(:different_title_list) { create(:subscriber_list, title: 'Space') }
    let!(:not_on_govdelivery_list) { create(:subscriber_list, title: nil) }
    let!(:errors_at_govdelivery_list) { create(:subscriber_list, title: nil) }

    before do
      allow(client).to receive(:fetch_topic).with(missing_title_list.gov_delivery_id)
        .and_return(double(name: 'I have a name'))
      allow(client).to receive(:fetch_topic).with(matching_title_list.gov_delivery_id)
        .and_return(double(name: 'Education'))
      allow(client).to receive(:fetch_topic).with(different_title_list.gov_delivery_id)
        .and_return(double(name: 'Something else'))
      allow(client).to receive(:fetch_topic).with(not_on_govdelivery_list.gov_delivery_id)
        .and_raise(GovDelivery::Client::TopicNotFound)
      allow(client).to receive(:fetch_topic).with(errors_at_govdelivery_list.gov_delivery_id)
        .and_raise(GovDelivery::Client::UnknownError.new("Error message"))
    end

    it 'fetches each topic from GovDelivery' do
      expect(client).to receive(:fetch_topic).exactly(5).times
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
        errors_at_govdelivery_list
      ].each { |subscriber_list| subscriber_list.reload }

      expect(matching_title_list.title).to eq('Education')
      expect(different_title_list.title).to eq('Space')
      expect(not_on_govdelivery_list.title).to eq(nil)
      expect(errors_at_govdelivery_list.title).to eq(nil)
    end

    it 'logs everything at the appropriate level' do
      [
        "Fetching and updating titles for 5 subscriber lists",
        "#{missing_title_list.gov_delivery_id}: title updated to match GovDelivery topic",
        "#{matching_title_list.gov_delivery_id}: already has matching title",
        "",
        "Done:",
        "  updated: 1",
        "  already_matching: 1",
        "  different: 1",
        "  not_found: 1",
        "  error_fetching: 1"
      ].each do |message|
        expect(logger).to receive(:info).with(message)
      end

      [
        "#{different_title_list.gov_delivery_id}: has GD name Something else but EEA title Space; not overwriting existing title with name",
        "#{not_on_govdelivery_list.gov_delivery_id}: topic not found on GovDelivery",
        "#{errors_at_govdelivery_list.gov_delivery_id}: error fetching topic from GovDelivery: Error message"
      ].each do |message|
        expect(logger).to receive(:warn).with(message)
      end

      subject.run
    end
  end
end

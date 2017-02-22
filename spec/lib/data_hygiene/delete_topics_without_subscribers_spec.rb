require 'rails_helper'
require 'data_hygiene/delete_topics_without_subscribers'

RSpec.describe DataHygiene::DeleteTopicsWithoutSubscribers do
  let!(:subscriber_list) { create(:subscriber_list, title: 'Test') }
  let(:client) { double('GovDelivery::Client') }
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }
  subject { described_class.new(client: client, input: input, output: output) }

  describe '#with_zero_subscribers' do
    before do
      allow(client).to receive(:fetch_topic).and_return(fetch_topics_response)
    end

    context 'when the topic has no subscribers' do
      let(:fetch_topics_response) { { 'subscribers_count' => 0 } }

      it 'is included in the list' do
        expect(subject.with_zero_subscribers).to include(subscriber_list)
      end
    end

    context 'when the topic has subscribers' do
      let(:fetch_topics_response) { { 'subscribers_count' => 2 } }

      it 'is not included in the list' do
        expect(subject.with_zero_subscribers).not_to include(subscriber_list)
      end
    end

    context 'when the topic does not exist' do
      let(:fetch_topics_response) { nil }

      it 'is not included in the list' do
        expect(subject.with_zero_subscribers).not_to include(subscriber_list)
      end
    end

    context '#when the GovDelivery `fetch_topic` endpoint has an error' do
      let(:fetch_topics_response) { { 'subscribers_count' => 0 } }
      before do
        allow(client).to receive(:fetch_topic)
          .with(subscriber_list.gov_delivery_id)
          .and_raise(GovDelivery::Client::UnknownError)
      end

      it 'marks the subscriber list as having an error' do
        expect(subject.with_gov_delivery_error).to include(subscriber_list)
      end

      it 'continues to process the remaining items in the list' do
        second_subscriber_list = create(:subscriber_list, title: 'Other', gov_delivery_id: 'beta')
        expect(subject.with_zero_subscribers).to include(second_subscriber_list)
      end
    end
  end

  describe '#with_gov_delivery_error' do
    before do
      allow(client).to receive(:fetch_topic).and_return(fetch_topics_response)
    end

    subject { described_class.new(client: client, input: input, output: output) }

    context 'when the topic has no subscribers' do
      let(:fetch_topics_response) { { 'subscribers_count' => 0 } }

      it 'is not included in the list' do
        expect(subject.with_gov_delivery_error).not_to include(subscriber_list)
      end
    end

    context 'when the topic has subscribers' do
      let(:fetch_topics_response) { { 'subscribers_count' => 2 } }

      it 'is not included in the list' do
        expect(subject.with_gov_delivery_error).not_to include(subscriber_list)
      end
    end

    context 'when the topic does not exist' do
      let(:fetch_topics_response) { nil }

      it 'is included in the list' do
        expect(subject.with_gov_delivery_error).to include(subscriber_list)
      end
    end
  end

  describe '#call' do
    before do
      allow(client).to receive(:fetch_topic).and_return('subscribers_count' => 0)
      allow(client).to receive(:delete_topic)
    end

    context 'when the user enters the delete command' do
      let(:expected_log_output) do
        [
          ".",
          '1 subscriber lists without subscribers',
          "#{subscriber_list.gov_delivery_id} - Test",
          '',
          '1 subscriber lists without subscribers, enter `delete` to delete from database and GovDelivery: ',
          "Deleting: #{subscriber_list.gov_delivery_id}",
          ''
        ].join("\n")
      end

      before do
        input.puts('delete')
        input.rewind
        allow(client).to receive(:delete_topic)
      end

      it 'deletes a subscriber list with 0 subscribers' do
        expect(client).to receive(:delete_topic).with(subscriber_list.gov_delivery_id)

        subject.call
      end

      it 'deletes the record from the database' do
        expect { subject.call }.to change { SubscriberList.count }.by(-1)
      end

      it 'correctly logs the process' do
        subject.call
        output.rewind

        expect(output.read).to eq(expected_log_output)
      end

      context '#when the GovDelivery `delete_topic` endpoint has an error' do
        let!(:second_subscriber_list) { create(:subscriber_list, title: 'Other', gov_delivery_id: 'beta') }
        let(:expected_log_output) do
          [
            "..",
            '2 subscriber lists without subscribers',
            "#{subscriber_list.gov_delivery_id} - #{subscriber_list.title}",
            "#{second_subscriber_list.gov_delivery_id} - #{second_subscriber_list.title}",
            '',
            '2 subscriber lists without subscribers, enter `delete` to delete from database and GovDelivery: ',
            "Deleting: #{subscriber_list.gov_delivery_id}",
            "---- Error deleting: #{subscriber_list.gov_delivery_id}",
            "Deleting: #{second_subscriber_list.gov_delivery_id}",
            ''
          ].join("\n")
        end
        before do
          allow(client).to receive(:delete_topic)
            .with(subscriber_list.gov_delivery_id)
            .and_raise(GovDelivery::Client::UnknownError)
        end

        it 'reports the error and continues deleting' do
          subject.call
          output.rewind

          expect(output.read).to eq(expected_log_output)
        end
      end
    end

    context 'when the user does not enter the delete command' do
      before do
        input.puts('skip')
        input.rewind
      end

      it 'does not delete any subscriber lists' do
        expect(client).not_to receive(:delete_topic)

        subject.call
      end

      it 'does not delete the record from the database' do
        expect { subject.call }.not_to change { SubscriberList.count }
      end
    end
  end
end

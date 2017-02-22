require 'rails_helper'

RSpec.describe DataHygiene::DataSync do
  let(:logger) { double(:logger, info: true, warn: true) }
  let(:topics) do
    [{ 'name' => 'Topic A', 'code' => 'TA' },{ 'name' => 'Topic B', 'code' => 'TB' }]
  end
  let(:gov_delivery_client) { double(:gov_delivery_client, fetch_topics: { 'topics' => topics }) }
  subject { described_class.new(logger, 0) }

  context 'when ALLOW_GOVDELIVERY_SYNC is not set' do
    it 'does not connect to the external service' do
      expect(Services).not_to receive(:gov_delivery)

      subject.run
    end
  end

  context 'when non-staging host is not set' do
    before do
      allow(ENV).to receive(:[]).and_return('')
      allow(ENV).to receive(:[]).with('ALLOW_GOVDELIVERY_SYNC').and_return('allow')
      allow(EmailAlertAPI.config).to receive(:gov_delivery).and_return(hostname: "api.govdelivery.com")
    end

    it 'does not connect to the external service' do
      expect(Services).not_to receive(:gov_delivery)

      subject.run
    end
  end

  context 'when valid' do
    before do
      allow(ENV).to receive(:[]).and_return('')
      allow(ENV).to receive(:[]).with('ALLOW_GOVDELIVERY_SYNC').and_return('allow')
      allow(EmailAlertAPI.config).to receive(:gov_delivery).and_return(hostname: "stage-api.govdelivery.com")
      allow(Services).to receive(:gov_delivery).and_return(gov_delivery_client)
    end

    it "correctly deleted topics that don't exist in database" do
      create(:subscriber_list, title: 'Topic A', gov_delivery_id: 'TA')

      expect(gov_delivery_client).to receive(:delete_topic).with('TB')

      subject.run
    end

    it "logs deletes" do
      create(:subscriber_list, title: 'Topic A', gov_delivery_id: 'TA')

      allow(gov_delivery_client).to receive(:delete_topic).with('TB')
      expect(logger).to receive(:warn).with("Deleting remote topics..")
      expect(logger).to receive(:warn).with("-- Deleting TB - Topic B")

      subject.run
    end

    it 'correctly creates topics that are missing from GovDelivery' do
      create(:subscriber_list, title: 'Topic A', gov_delivery_id: 'TA')
      create(:subscriber_list, title: 'Topic B', gov_delivery_id: 'TB')
      create(:subscriber_list, title: 'Topic C', gov_delivery_id: 'TC')

      expect(gov_delivery_client).to receive(:create_topic).with('Topic C', 'TC')

      subject.run
    end

    it "will delete and recreate topics that don't match on title and gov_delivery_id" do
      create(:subscriber_list, title: 'Topic alpha', gov_delivery_id: 'TA')
      create(:subscriber_list, title: 'Topic B', gov_delivery_id: 'Tb')

      expect(gov_delivery_client).to receive(:delete_topic).with('TA')
      expect(gov_delivery_client).to receive(:delete_topic).with('TB')

      expect(gov_delivery_client).to receive(:create_topic).with('Topic alpha', 'TA')
      expect(gov_delivery_client).to receive(:create_topic).with('Topic B', 'Tb')

      subject.run
    end

    it "won't delete and recreate topics that don't match on title and gov_delivery_id if a record exists that does match on title and gov_delivery_id" do
      create(:subscriber_list, title: 'Topic alpha', gov_delivery_id: 'TA')
      create(:subscriber_list, title: 'Topic A', gov_delivery_id: 'TA')
      create(:subscriber_list, title: 'Topic B', gov_delivery_id: 'TB')

      expect(gov_delivery_client).not_to receive(:delete_topic)
      expect(gov_delivery_client).not_to receive(:create_topic)

      subject.run
    end


    it "won't perform any actions if everything matches" do
      create(:subscriber_list, title: 'Topic A', gov_delivery_id: 'TA')
      create(:subscriber_list, title: 'Topic B', gov_delivery_id: 'TB')

      expect(gov_delivery_client).not_to receive(:delete_topic)
      expect(gov_delivery_client).not_to receive(:create_topic)

      subject.run
    end
  end
end

require 'rails_helper'

RSpec.describe NotificationLogReporting do
  subject { described_class.new(Date.yesterday..Date.tomorrow) }
  context '#duplicates' do
    it 'returns a list of duplicates' do
      govuk_request_id = SecureRandom.uuid
      create(govuk_request_id: govuk_request_id)
      create(govuk_request_id: govuk_request_id, gov_delivery_ids: ["AAAAA", "BBBBB"])

      expect(subject.duplicates).to eq(
        [
          [
            "email_alert_api",
            govuk_request_id,
            [["TOPIC A", "TOPIC B"], ["AAAAA", "BBBBB"]]
          ]
        ]
      )
    end
  end

  context '#missing - grouped by gov delivery ids with count of occurances' do
    context 'when notification for GovUkDelivery and not for EmailAlertApi' do
      it 'detects missing notifications' do
        govuk_request_id = SecureRandom.uuid
        create(govuk_request_id: govuk_request_id, emailing_app: 'gov_uk_delivery')

        expect(subject.missing).to eq(
          '["TOPIC A","TOPIC B"]' => 1
        )
      end
    end

    context 'when notification for EmailAlertApi and not for GovUkDelivery' do
      it 'does not detect any missing notifications' do
        govuk_request_id = SecureRandom.uuid
        create(govuk_request_id: govuk_request_id)

        expect(subject.missing).to eq({})
      end
    end

    context 'when notification for both EmailAlertApi and GovUkDelivery' do
      it 'does not detect any missing notifications' do
        govuk_request_id = SecureRandom.uuid
        create(govuk_request_id: govuk_request_id)
        create(govuk_request_id: govuk_request_id, emailing_app: 'gov_uk_delivery')

        expect(subject.missing).to eq({})
      end
    end
  end

  context '#different' do
    context 'when notification for GovUkDelivery and not for EmailAlertApi' do
      it 'does not detect any differences' do
        govuk_request_id = SecureRandom.uuid
        create(govuk_request_id: govuk_request_id, emailing_app: 'gov_uk_delivery')

        expect(subject.different).to eq({})
      end
    end

    context 'when notification for GovUkDelivery and EmailAlertApi which is sent to different gov_delivery_ids lists' do
      it 'detects notifications with different gov delivery ids' do
        govuk_request_id = SecureRandom.uuid
        create(govuk_request_id: govuk_request_id)
        create(govuk_request_id: govuk_request_id, emailing_app: 'gov_uk_delivery', gov_delivery_ids: ["AAAAA", "BBBBB"])

        expect(subject.different).to eq(
          ['["AAAAA","BBBBB"]', '["TOPIC A","TOPIC B"]'] => 1
        )
      end
    end

    it 'gov_delivery_ids ordering does not affect matching' do
      govuk_request_id = SecureRandom.uuid
      a = create(govuk_request_id: govuk_request_id, gov_delivery_ids: ["BBBBB", "AAAAA"])
      create(govuk_request_id: govuk_request_id, emailing_app: 'gov_uk_delivery', gov_delivery_ids: ["AAAAA", "BBBBB"])

      expect(subject.different).to eq({})
    end
  end

  def create(params)
    defaults = {
      govuk_request_id: SecureRandom.uuid,
      content_id: SecureRandom.uuid,
      public_updated_at: Time.now.to_s,
      links: {},
      tags: {},
      document_type: 'annoucement',
      emailing_app: 'email_alert_api',
      gov_delivery_ids: ['TOPIC A', 'TOPIC B']
    }
    NotificationLog.create!(defaults.merge(params))
  end
end

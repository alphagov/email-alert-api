require 'rails_helper'

RSpec.describe EmailAlertAPI::Config do

  describe 'Gov Delivery account code' do
    subject { EmailAlertAPI::Config.new(Rails.env) }

    it 'returns the value specified in gov_delivery.yml' do
      expected_code = 'UKGOVUK'

      expect(subject.gov_delivery.fetch(:account_code)).to eq(expected_code)
    end

    context 'when an ACCOUNT_CODE is provided in the environment' do
      before do
        ENV['GOVDELIVERY_ACCOUNT_CODE'] = 'UKGOVUK-2'
      end

      it 'returns the code from the environment variable' do
        expected_code = 'UKGOVUK-2'

        expect(subject.gov_delivery.fetch(:account_code)).to eq(expected_code)
      end

      after do
        ENV.delete 'GOVDELIVERY_ACCOUNT_CODE'
      end
    end
  end

end

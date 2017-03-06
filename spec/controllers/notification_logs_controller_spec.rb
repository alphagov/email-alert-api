require 'rails_helper'

RSpec.describe NotificationLogsController, type: :controller do
  let(:params) do
    {
      govuk_request_id: 'aaaaaaa-111111',
      content_id: "111111-aaaaaa",
      public_updated_at: "2017-02-21T14:58:45+00:00",
      document_type: 'guidence',
      emailing_app: 'email_alert_api',
      publishing_app: 'Whitehall',
      gov_delivery_ids: ['Topic 2', 'Topic 1']
    }
  end

  it 'creates a delivery log record' do
    expect { post :create, params.merge(format: :json) }.to change { NotificationLog.count }.by(1)

    expect(NotificationLog.last).to have_attributes(
      govuk_request_id: 'aaaaaaa-111111',
      content_id: "111111-aaaaaa",
      public_updated_at: Time.parse("2017-02-21T14:58:45+00:00"),
      document_type: 'guidence',
      emailing_app: 'email_alert_api',
      publishing_app: 'Whitehall',
      gov_delivery_ids: ['Topic 1', 'Topic 2']
    )
  end

  it 'returns a 202 success response' do
    post :create, params.merge(format: :json)

    expect(response.code).to eq('202')
  end
end

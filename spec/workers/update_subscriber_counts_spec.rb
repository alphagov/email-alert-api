require "rails_helper"

RSpec.describe UpdateSubscriberCounts do
  describe '#perform' do
    it "updates the counts" do
      working_subscriber_list = create(:subscriber_list)
      stub_govdelivery(working_subscriber_list)
      error_list = create(:subscriber_list)
      stub_govdelivery_error(error_list)

      UpdateSubscriberCounts.new.perform

      expect(working_subscriber_list.reload.subscriber_count).to eql(12345)
    end

    def stub_govdelivery(subscriber_list)
      body = <<-XML.strip_heredoc
        <?xml version="1.0" encoding="UTF-8"?>
        <topic>
          <subscribers-count type="integer">12345</subscribers-count>
        </topic>
      XML

      stub_request(:get, "http://govdelivery-api.example.com/api/account/UKGOVUK/topics/#{subscriber_list.gov_delivery_id}.xml").
        to_return(status: 200, body: body)
    end

    def stub_govdelivery_error(subscriber_list)
      stub_request(:get, "http://govdelivery-api.example.com/api/account/UKGOVUK/topics/#{subscriber_list.gov_delivery_id}.xml").
        to_return(status: 500)
    end
  end
end

module GovDeliveryHelpers
  def stub_gov_delivery_topic_creation
    config = EmailAlertAPI.config.gov_delivery
    base_url = "http://#{config.fetch(:username)}:#{config.fetch(:password)}@#{config.fetch(:hostname)}/api/account/#{config.fetch(:account_code)}"

    stub_request(:post, base_url + "/topics.xml")
      .with(body: /This is a sample title/)
      .to_return(body: %{
        <?xml version="1.0" encoding="UTF-8"?>
        <topic>
          <to-param>UKGOVUK_1234</to-param>
          <topic-uri>/api/account/UKGOVUK/topics/UKGOVUK_1234.xml</topic-uri>
          <link rel="self" href="/api/account/UKGOVUK/topics/UKGOVUK_1234"/>
        </topic>
      })
  end
end

RSpec.configure do |config|
  config.include(GovDeliveryHelpers, type: :model)
  config.before(:example, type: :model) do
    stub_gov_delivery_topic_creation
  end
end

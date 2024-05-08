ENV["RAILS_ENV"] = "test"
ENV["PACT_DO_NOT_TRACK"] = "true"

require "pact/provider/rspec"
require "webmock/rspec"
require "factory_bot_rails"
require "database_cleaner/active_record"

require "plek"
require "gds_api/test_helpers/account_api"

require ::File.expand_path("../../config/environment", __dir__)

Pact.configure do |config|
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
  config.include FactoryBot::Syntax::Methods
  config.include GdsApi::TestHelpers::AccountApi
end

WebMock.allow_net_connect!
DatabaseCleaner.allow_remote_database_url = true

def url_encode(str)
  ERB::Util.url_encode(str)
end

Pact.service_provider "Email Alert API" do
  honours_pact_with "GDS API Adapters" do
    if ENV["PACT_URI"]
      pact_uri(ENV["PACT_URI"])
    else
      base_url = "https://govuk-pact-broker-6991351eca05.herokuapp.com"
      path = "pacts/provider/#{url_encode(name)}/consumer/#{url_encode(consumer_name)}"
      version_modifier = "versions/#{url_encode(ENV.fetch('PACT_CONSUMER_VERSION', 'branch-main'))}"

      pact_uri("#{base_url}/#{path}/#{version_modifier}")
    end
  end
end

Pact.provider_states_for "GDS API Adapters" do
  set_up do
    GDS::SSO.test_user = create(:user, permissions: %w[internal_app])
  end

  tear_down do
    DatabaseCleaner.clean_with :truncation
  end

  provider_state "a subscription with the uuid 719efe7b-00d0-4168-ac30-99fe6093e3fc exists" do
    set_up do
      create(
        :subscription,
        id: "719efe7b-00d0-4168-ac30-99fe6093e3fc",
        subscriber_list: create(:subscriber_list),
        subscriber: create(:subscriber, id: 1, address: "test@example.com"),
        frequency: :immediately,
      )
    end
  end

  provider_state "a subscriber list with the tag topic: motoring/road_rage exists" do
    set_up do
      create(:subscriber_list)
    end
  end

  provider_state "a subscriber list with slug title-1 exists" do
    set_up do
      create(:subscriber_list, slug: "title-1")
    end
  end

  provider_state "a subscriber list with id 1 exists" do
    set_up do
      create(:subscriber_list, id: 1)
    end
  end

  provider_state "a bulk_unsubscribe message with the sender_message_id b735f541-c29c-4752-b084-c4ddb47aee73 and subscriber_list with slug title-1 exists" do
    set_up do
      create(:subscriber_list, slug: "title-1")
      create(
        :message,
        sender_message_id: "b735f541-c29c-4752-b084-c4ddb47aee73",
      )
    end
  end

  provider_state "a content change with content_id 5fc8fb2b-c0b1-4490-99cb-c987a53afb75 exists" do
    set_up do
      create(
        :content_change,
        content_id: "5fc8fb2b-c0b1-4490-99cb-c987a53afb75",
        public_updated_at: "2022-01-01 00:00:00 +0000",
      )
    end
  end

  provider_state "a subscriber exists" do
    set_up do
      create(:subscriber, id: 1, address: "test@example.com")
    end
  end

  provider_state "a verified govuk_account_session exists with a matching subscriber" do
    set_up do
      stub_account_api_user_info(
        id: "internal-user-id",
        email: "test@example.com",
        email_verified: true,
      )
      create(:subscriber, id: 1, address: "test@example.com")
    end
  end

  provider_state "a govuk_account_session exists but isn't verified" do
    set_up do
      stub_account_api_user_info(
        id: "internal-user-id",
        email: "test@example.com",
        email_verified: false,
      )
    end
  end

  provider_state "a verified govuk_account_session exists with a linked subscriber" do
    set_up do
      stub_account_api_user_info(
        id: "internal-user-id",
        email: "test@example.com",
        email_verified: true,
      )
      create(:subscriber, id: 1, address: "test@example.com", govuk_account_id: "internal-user-id")
    end
  end

  provider_state "the account api can't find the user by session" do
    set_up do
      stub_account_api_unauthorized_user_info
    end
  end
end

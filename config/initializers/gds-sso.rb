GDS::SSO.config do |config|
  config.user_model = "User"
  config.oauth_id = ENV.fetch("OAUTH_ID", "abcdefg")
  config.oauth_secret = ENV.fetch('OAUTH_SECRET', "secret")
  config.oauth_root_url = Plek.find("signon")
  config.cache = Rails.cache
  config.additional_mock_permissions_required = %w[internal_app]
end

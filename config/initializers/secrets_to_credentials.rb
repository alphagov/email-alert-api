# Rails 7 has begung to deprecate Rails.application.secrets in favour
# of Rails.application.credentials, but that adds the burden of master key
# adminstration without giving us any benefit (because our production
# secrets are handled as env vars, not committed to our repo. Here we
# loads the config/secrets.YML values into Rails.application.credentials,
# retaining the existing behaviour while dropping deprecated references.

Rails.application.credentials.merge!(Rails.application.config_for(:secrets))

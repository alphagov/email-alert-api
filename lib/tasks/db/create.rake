namespace :db do
  # We need the hstore extension, which can only be enabled by a superuser.
  # We'd rather not have the app using a superuser role, so shell out and use
  # the postgres user instead.
  task :create do
    database_name = Rails.configuration.database_configuration[Rails.env]['database']
    system("sudo -u postgres psql -d #{database_name} -c 'CREATE EXTENSION IF NOT EXISTS hstore'")
  end
end

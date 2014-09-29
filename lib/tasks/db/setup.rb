namespace :db do
  task :setup do
    # Hardcoded for now to test if this works.
    config = CONFIG.fetch(:postgres)
    database_name = config[:database]
    system("sudo -u postgres psql -d template1 -c 'DROP DATABASE #{database_name}'")
    system("sudo -u postgres psql -d template1 -c 'CREATE DATABASE #{database_name}'")
    system("sudo -u postgres psql -d #{database_name} -c 'CREATE EXTENSION IF NOT EXISTS hstore'")
  end
end

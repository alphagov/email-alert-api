namespace :db do
  desc "Run migrations"
  task :migrate do
    require "logger"
    require "sequel"

    Sequel.extension :migration

    config = CONFIG.fetch(:postgres)
    uri = "postgres://%{host}/%{database}?user=%{user}&password=%{password}" % config
    db = Sequel.connect(uri, logger: Logger.new($stdout))

    Sequel::Migrator.run(db, config.fetch(:migrations_dir))
  end

  desc "Set up database"
  task :setup do
    # Hardcoded for now to test if this works.
    config = CONFIG.fetch(:postgres)
    database_name = config[:database]
    system("psql -d postgres -c 'DROP DATABASE #{database_name}'")
    system("psql -d postgres -c 'CREATE DATABASE #{database_name}'")
    system("sudo -u postgres psql -d #{database_name} -c 'CREATE EXTENSION IF NOT EXISTS hstore'")
  end
end

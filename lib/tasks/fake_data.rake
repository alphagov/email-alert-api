require "fake_data"

namespace :fake_data do
  desc "Insert fake data for testing the system"
  task :insert, [] => :environment do
    FakeData.insert
  end

  desc "Clear fake data for testing the system"
  task :delete, [] => :environment do
    FakeData.delete
  end
end

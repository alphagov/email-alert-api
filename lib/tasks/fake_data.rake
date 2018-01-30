require "fake_data"

namespace :fake_data do
  desc "Insert fake data for testing the system"
  task :insert, [:proportion] => :environment do |_t, args|
    FakeData.insert(proportion: args[:proportion].to_f)
  end

  desc "Clear fake data for testing the system"
  task :delete, [] => :environment do
    FakeData.delete
  end
end

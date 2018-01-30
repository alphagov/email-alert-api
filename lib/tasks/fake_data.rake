require "fake_data"

desc "Generate fake data for testing the system"
task :fake_data, [] => :environment do
  FakeData.call
end

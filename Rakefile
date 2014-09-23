require_relative "configuration"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require 'cucumber'
require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = "features --format pretty"
end

task default: [
  "spec",
  "cucumber",
]

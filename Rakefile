# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

Rails.application.load_tasks

begin
  require "pact/tasks"
rescue LoadError
  # Pact isn't available in all environments
end

unless Rails.env.production?
  Rake::Task[:default].clear
  task default: %i[lint spec pact:verify]
end

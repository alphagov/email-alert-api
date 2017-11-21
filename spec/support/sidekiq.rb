require 'sidekiq/testing'

RSpec.configure do |config|
  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  config.before(:example) do
    Sidekiq::Testing.inline!
  end
end

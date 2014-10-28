require 'sidekiq/testing'

RSpec.configure do |config|
  config.before(:example) do
    Sidekiq::Testing.inline!
  end
end

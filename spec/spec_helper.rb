# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require "pry"
require "awesome_print"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end
end

require_relative "../config/env"

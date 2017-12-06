require "benchmark"
require "load_tester"

namespace :load_tests do
  desc "Run a load test of the DeliveryRequestWorker by triggering requests"
  task :delivery_request_workers, [:number] => :environment do |_t, args|
    results = Benchmark.measure do
      LoadTester.test_delivery_request_workers(args[:number].to_i)
    end

    puts results
  end
end

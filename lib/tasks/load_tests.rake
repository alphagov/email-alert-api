require "benchmark"
require "load_tester"

namespace :load_tests do
  desc "Run a load test of the DeliveryRequestWorker by triggering 83,333 requests"
  task :delivery_request_worker, [] => :environment do |_t, _args|
    results = Benchmark.measure do
      LoadTester.test_delivery_request_workers(83_333)
    end

    puts results
  end
end

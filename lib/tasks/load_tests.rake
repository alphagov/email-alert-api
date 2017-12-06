require "benchmark"
require "load_tester"

namespace :load_tests do
  desc "Run a load test of the DeliveryRequestWorker by triggering requests"
  task :delivery_request_worker, [:number] => :environment do |_t, args|
    results = Benchmark.measure do
      LoadTester.test_delivery_request_workers(args[:number].to_i)
    end

    puts results
  end

  desc "Run a load test of the EmailGenerationWorker by triggering requests"
  task :email_generation_worker, [:number] => :environment do |_t, args|
    results = Benchmark.measure do
      LoadTester.test_email_generation_workers(args[:number].to_i)
    end

    puts results
  end

  desc "Run a load test of the SubscriptionContentWorker by triggering requests"
  task :subscription_content_worker, [:number] => :environment do |_t, args|
    results = Benchmark.measure do
      LoadTester.test_subscription_content_workers(args[:number].to_i)
    end

    puts results
  end
end

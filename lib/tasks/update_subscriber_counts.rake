desc "Schedule a worker to update the subscriber list counts"
task schedule_update_subscriber_counts: [:environment] do
  UpdateSubscriberCounts.perform_async
end

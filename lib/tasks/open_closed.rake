namespace :open_closed do
  desc "Notify subscribers about the retirement of open/closed consultation topics"
  task notify_subscribers_about_retirement: [:environment] do
    retirer = OpenClosedRetirer.new(run_for_real: ENV["RUN_FOR_REAL"])
    retirer.notify_subscribers_about_retirement!
  end

  desc "Remove open/closed consultation topics from govdelivery and the database"
  task remove_subscriber_lists_and_topics: [:environment] do
    retirer = OpenClosedRetirer.new(run_for_real: ENV["RUN_FOR_REAL"])
    retirer.remove_subscriber_lists_and_topics!
  end
end

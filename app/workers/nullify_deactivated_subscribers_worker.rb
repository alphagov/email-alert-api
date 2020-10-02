class NullifyDeactivatedSubscribersWorker < ApplicationWorker
  def perform
    run_with_advisory_lock(Subscriber, "nullify") do
      subscribers.find_each(&:nullify)
    end
  end

private

  def subscribers
    Subscriber
      .deactivated
      .not_nullified
      .where("deactivated_at < ?", 28.days.ago)
  end
end

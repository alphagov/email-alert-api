class NullifyDeactivatedSubscribersWorker
  include Sidekiq::Worker

  def perform
    run_only_once do
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

  def run_only_once
    Subscriber.with_advisory_lock("nullify_deactivated_subscribers", timeout_seconds: 0) do
      yield
    end
  end
end

# This is a legacy class that is used as Sidekiq stores the names of workers
# once Sidekiq no longer has this class in it's queue it can be removed.
class SubscriptionContentWorker
  include Sidekiq::Worker

  def perform(content_change_id, _batch_size = 1000)
    ProcessContentChangeWorker.new.perform(content_change_id)
  end
end

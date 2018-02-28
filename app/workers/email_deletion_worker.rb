class EmailDeletionWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cleanup

  LOCK_NAME = "email_deletion_worker".freeze

  def perform
    Email.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      Email.deleteable.in_batches { |b| b.delete_all }
    end
  end
end

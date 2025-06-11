class ApplicationJob
  include Sidekiq::Job

private

  def run_with_advisory_lock(model, unique_ref, &block)
    ApplicationRecord.with_advisory_lock("#{model}-#{unique_ref}", timeout_seconds: 0, &block)
  end
end

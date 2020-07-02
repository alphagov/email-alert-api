class RecoverLostJobsWorker
  include Sidekiq::Worker

  def perform(model, worker)
    orphan_records(model).each do |record|
      worker.perform_async(record.id)
    end
  end

private

  def orphan_records(model)
    model.unprocessed.where("created_at <= ?", 1.hour.ago).select { |record| orphan?(record) }
  end

  def orphan?(record)
    !queued?(record) || !retrying?(record)
  end

  def queued?(record)
    Sidekiq::Queue.new("process_and_generate_emails").any? { |job| job.args[0] == record.id }
  end

  def retrying?(record)
    Sidekiq::RetrySet.new.any? { |job| job.args[0] == record.id }
  end
end

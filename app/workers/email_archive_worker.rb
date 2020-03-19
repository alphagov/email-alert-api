class EmailArchiveWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cleanup

  LOCK_NAME = "email_archive_worker".freeze
  BATCH_SIZE = 1000

  def perform
    return unless ENV.include?("EMAIL_ARCHIVE_S3_ENABLED")

    update_counts(type: :successes)
    update_counts(type: :failures)

    Email.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      start_time = Time.zone.now
      archived_count = 0

      loop do
        batch = EmailArchiveQuery.call.limit(BATCH_SIZE).map(&:serializable_hash)
        break if batch.empty?

        archived_count += archive_batch(batch)

        break if batch.length < BATCH_SIZE
      end

      log_complete(archived_count, start_time, Time.zone.now)
    end
  end

private

  def archive_batch(batch)
    archived_at = Time.zone.now
    send_to_s3(batch, archived_at)
    mark_emails_as_archived(batch.pluck("id"), archived_at)
  end

  def send_to_s3(batch, archived_at)
    archive = batch.map { |b| EmailArchivePresenter.for_s3(b, archived_at) }
    S3EmailArchiveService.call(archive)
  end

  def mark_emails_as_archived(ids, archived_at)
    Email.where(id: ids).update_all(archived_at: archived_at)
  end

  def log_complete(archived, start_time, end_time)
    seconds = (end_time - start_time).round(2)
    message = "Archived #{archived} emails in #{seconds} seconds"
    logger.info(message)
  end

  def update_counts(type: :successes)
    status = type == :successes ? :sent : :failed
    status_hashes = Email.where(status: status).where.not(subscriber_id: nil).group(:subscriber_id).count

    status_hashes.each_slice(BATCH_SIZE) do |list|
      ActiveRecord::Base.connection.execute(bulk_update_sql(list, type: type))
    end
  end

  def bulk_update_sql(value_list, type: :failures)
    values_string = value_list.map { |k, v| "(#{k},#{v})" }.join(",")
    <<-SQL
    UPDATE subscribers
      SET
        #{type} = subscribers.#{type} + values.#{type}
      FROM (
        VALUES
          #{values_string}
      ) AS values (id, #{type})
      WHERE subscribers.id = values.id
    SQL
  end
end

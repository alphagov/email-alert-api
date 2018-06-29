class EmailArchiveWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cleanup

  LOCK_NAME = "email_archive_worker".freeze

  def perform
    Email.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      start_time = Time.zone.now
      archived_count = 0

      EmailArchiveQuery.call.in_batches do |batch|
        Email.transaction do
          archived_count += archive_batch(batch.as_json)
        end
      end

      log_complete(archived_count, start_time, Time.zone.now)
    end
  end

private

  def archive_batch(batch)
    archived_at = Time.zone.now
    exported_at = nil

    if ENV.include?("EMAIL_ARCHIVE_S3_ENABLED")
      send_to_s3(batch, archived_at)
      exported_at = archived_at
    end

    import_batch(batch, archived_at, exported_at)
    mark_emails_as_archived(batch.pluck("id"), archived_at)
  end

  def import_batch(batch, archived_at, exported_at)
    archive = batch.map do |b|
      EmailArchivePresenter.for_db(b, archived_at, exported_at)
    end

    columns = archive.first.keys.map(&:to_s)
    values = archive.map(&:values)
    EmailArchive.import(columns, values, validate: false)
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
end

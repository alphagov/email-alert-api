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
          archived_count += archive_batch(batch)
        end
      end

      log_complete(archived_count, start_time, Time.zone.now)
    end
  end

private

  def archive_batch(batch)
    archived_at = Time.zone.now

    import_batch(batch, archived_at)
    Email.where(id: batch.pluck(:id)).update_all(archived_at: archived_at)
  end

  def import_batch(batch, archived_at)
    to_import = batch.as_json.map { |e| build_email_archive(e, archived_at) }
    columns = to_import.first.keys.map(&:to_s)
    values = to_import.map(&:values)
    EmailArchive.import(columns, values, validate: false)
  end

  def build_email_archive(email_data, archived_at)
    content_change = build_content_change(email_data)

    {
      archived_at: archived_at,
      content_change: content_change,
      created_at: email_data.fetch("created_at"),
      finished_sending_at: email_data.fetch("finished_sending_at"),
      id: email_data.fetch("id"),
      sent: email_data.fetch("sent"),
      subject: email_data.fetch("subject"),
      subscriber_id: email_data.fetch("subscriber_id"),
    }
  end

  def build_content_change(email_data)
    return if email_data.fetch("content_change_ids").empty?

    if email_data.fetch("digest_run_ids").count > 1
      error = "Email with id: #{email_data['id']} is associated with "\
        "multiple digest runs: #{email_data['digest_run_ids'].join(', ')}"
      GovukError.notify(error)
    end

    {
      content_change_ids: email_data.fetch("content_change_ids"),
      digest_run_id: email_data.fetch("digest_run_ids").first,
      subscription_ids: email_data.fetch("subscription_ids"),
    }
  end

  def log_complete(archived, start_time, end_time)
    seconds = (end_time - start_time).round(2)
    message = "Archived #{archived} emails in #{seconds} seconds"
    logger.info(message)
  end
end

class EmailArchiveExporter
  def self.call(*args)
    new.call(*args)
  end

  def call(from_date, until_date)
    from_date = Date.parse(from_date)
    until_date = Date.parse(until_date)

    puts "Exporting records that finished sending from #{from_date} and before #{until_date}"

    total = (from_date...until_date).inject(0) { |sum, date| sum + export(date) }

    puts "Exported #{total} records"
  end

  private_class_method :new

private

  def export(date)
    puts "Exporting #{date}"
    start = Time.now

    count = 0

    loop do
      records = email_archive_records(date)

      break unless records.any?

      ExportToS3.call(records)

      count += records.count
      puts "Processed #{count} emails"
    end

    seconds = Time.now.to_i - start.to_i
    puts "Completed #{date} in #{seconds} seconds"

    count
  end

  def email_archive_records(date)
    EmailArchive
      .where(
        "finished_sending_at >= ? AND finished_sending_at < ?",
        date,
        date + 1.day
      )
      .where(exported_at: nil)
      .order(finished_sending_at: :asc, id: :asc)
      .limit(50_000)
      .as_json
  end

  class ExportToS3
    def self.call(*args)
      new.call(*args)
    end

    def call(records)
      send_to_s3(records)
      mark_as_exported(records)
    end

  private

    def send_to_s3(records)
      batch = records.map do |r|
        r.symbolize_keys.slice(
          :archived_at,
          :content_change,
          :created_at,
          :finished_sending_at,
          :id,
          :sent,
          :subject,
          :subscriber_id
        )
      end

      S3EmailArchiveService.call(batch)
    end

    def mark_as_exported(records)
      ids = records.map { |r| r["id"] }
      EmailArchive.where(id: ids).update_all(exported_at: Time.now)
    end
  end
end

class S3EmailArchiveService < ApplicationService
  attr_reader :batch

  # For batch we expect an array of hashes containing email data in the format
  # from EmailArchivePresenter
  def initialize(batch)
    @batch = batch
  end

  def call
    group_by_date(batch).map { |prefix, records| send_to_s3(prefix, records) }
  end

private

  def group_by_date(batch)
    batch.group_by do |item|
      # we group by date in this way to create partitions for s3/athena
      # these are grouped in case dates span more than one day
      Date.parse(
        item.fetch(:created_at_utc),
      ).strftime("year=%Y/month=%m/date=%d")
    end
  end

  def send_to_s3(prefix, records)
    records = records.sort_by { |r| r.fetch(:created_at_utc) }
    last_time = records.last[:created_at_utc]
    obj = bucket.object(object_name(prefix, last_time))
    obj.put(
      body: object_body(records),
      content_encoding: "gzip",
    )
  end

  def bucket
    @bucket ||= begin
                  s3 = Aws::S3::Resource.new
                  s3.bucket(ENV.fetch("EMAIL_ARCHIVE_S3_BUCKET"))
                end
  end

  def object_name(prefix, last_time)
    uuid = SecureRandom.uuid
    time = ActiveSupport::TimeZone["UTC"].parse(last_time)
    "email-archive/#{prefix}/#{time.to_s(:iso8601)}-#{uuid}.json.gz"
  end

  def object_body(records)
    data = records.map(&:to_json).join("\n") + "\n"
    ActiveSupport::Gzip.compress(data, Zlib::BEST_COMPRESSION)
  end
end

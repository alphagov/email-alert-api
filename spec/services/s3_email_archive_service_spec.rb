RSpec.describe S3EmailArchiveService do
  before :each do
    Aws.config[:s3] = { stub_responses: true }
  end

  around do |example|
    ClimateControl.modify(EMAIL_ARCHIVE_S3_BUCKET: 'my-bucket') { example.run }
  end

  def create_record(time: Time.now)
    {
      archived_at_utc: time.utc.to_s(:db),
      content_change: nil,
      created_at_utc: time.utc.to_s(:db),
      finished_sending_at_utc: time.utc.to_s(:db),
      id: SecureRandom.uuid,
      sent: true,
      subject: "Test email",
      subscriber_id: SecureRandom.uuid,
    }
  end

  it "Returns PutObjectOutput instances" do
    expect(described_class.call([create_record])).to match(
      [an_instance_of(Aws::S3::Types::PutObjectOutput)]
    )
  end

  it "creates a partioned path on S3" do
    time = "2018-06-28T09:00:00Z"

    expect_any_instance_of(Aws::S3::Bucket).to receive(:object)
      .with(%r{^email-archive/year=2018/month=06/date=28/#{time}-[a-z0-9-]*.json.gz$})
      .and_call_original
    described_class.call(
      [create_record(time: Time.parse(time))]
    )
  end

  it "puts a gzipped object onto S3" do
    time = Time.zone.parse("2018-06-28 00:00:00 BST")

    expect_any_instance_of(Aws::S3::Object).to receive(:put)
      .with(
        body: gzipped_match(%r/^{"archived_at_utc":"2018-06-27/),
        content_encoding: "gzip"
      ) do |args|
      end
    described_class.call(
      [create_record(time: time)]
    )
  end

  context "when the batch contains items with different finished_sending_at days" do
    let(:batch) do
      [
        create_record(time: Time.zone.parse("2018-06-28 10:00")),
        create_record(time: Time.zone.parse("2018-06-27 10:00")),
        create_record(time: Time.zone.parse("2018-06-27 11:00")),
        create_record(time: Time.zone.parse("2018-06-26 10:00")),
      ]
    end

    it "creates multiple objects" do
      expect(described_class.call(batch).length).to be(3)
    end
  end
end

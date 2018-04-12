class BulkEmailBuilder
  def initialize(subject:, body:, subscriber_lists:)
    @subject = subject
    @body = body
    @subscriber_lists = subscriber_lists
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :subject, :body, :subscriber_lists

  def columns
    %i(address subject body subscriber_id)
  end

  def records
    subscribers.map do |address, subscriber_id|
      [address, subject, body, subscriber_id]
    end
  end

  def subscribers
    Subscriber
      .activated
      .not_nullified
      .joins(:subscriptions)
      .where(subscriptions: { ended_at: nil, subscriber_list: subscriber_lists })
      .distinct
      .pluck(:address, :id)
  end
end

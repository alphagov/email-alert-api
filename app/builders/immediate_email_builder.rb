class ImmediateEmailBuilder
  def initialize(subscriber_content_changes)
    @subscriber_content_changes = subscriber_content_changes
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :subscriber_content_changes

  def records
    subscriber_content_changes.map do |subscriber_content_change|
      single_email_record(subscriber_content_change)
    end
  end

  def columns
    %i(address subject body)
  end

  def single_email_record(subscriber_content_change)
    subscriber = subscriber_content_change.fetch(:subscriber)
    content_change = subscriber_content_change.fetch(:content_change)

    [subscriber.address, subject(content_change), body(subscriber, content_change)]
  end

  def subject(content_change)
    "GOV.UK Update - #{content_change.title}"
  end

  def body(subscriber, content_change)
    <<~BODY
      #{presented_content_change(content_change)}
      ---

      #{unsubscribe_links(subscriber)}
    BODY
  end

  def presented_content_change(content_change)
    ContentChangePresenter.call(content_change)
  end

  def unsubscribe_links(subscriber)
    links = subscriber.subscriptions.map do |subscription|
      UnsubscribeLinkPresenter.call(uuid: subscription.uuid, title: subscription.subscriber_list.title)
    end

    links.join("\n\n")
  end
end

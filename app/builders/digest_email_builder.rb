class DigestEmailBuilder
  include EmailBuilderHelper
  def initialize(address:, subscription_content_changes:, digest_run:, subscriber_id:)
    @address = address
    @subscription_content_changes = subscription_content_changes
    @digest_run = digest_run
    @subscriber_id = subscriber_id
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.create!(
      address: address,
      subject: subject,
      body: body,
      subscriber_id: subscriber_id,
    )
  end

  private_class_method :new

private

  attr_reader :address, :subscription_content_changes, :digest_run, :subscriber_id

  def body
    <<~BODY
      #{opening_line}

      #{presented_results}

      &nbsp;

      ---

      #{permission_reminder}
      #{presented_manage_subscriptions_links(address)}

      &nbsp;

      #{feedback_link.strip}
    BODY
  end

  def presented_results
    subscription_content_changes.map { |content_change| presented_segment(content_change) }.join("\n&nbsp;\n\n")
  end

  def presented_segment(subscription_content_changes)
    <<~RESULT
      ##{subscription_content_changes.subscriber_list_title}&nbsp;

      #{deduplicate_and_present(subscription_content_changes.content_changes)}
      ---

      #{presented_unsubscribe_link(subscription_content_changes.subscription_id, subscription_content_changes.subscriber_list_title)}
    RESULT
  end

  def deduplicate_and_present(content_changes)
    presented_content_changes(
      deduplicated_content_changes(content_changes)
    )
  end

  def deduplicated_content_changes(content_changes)
    ContentChangeDeduplicatorService.call(content_changes)
  end

  def presented_content_changes(content_changes)
    changes = content_changes.map do |content_change|
      presented_content_change(content_change)
    end

    changes.join("\n---\n\n")
  end
end

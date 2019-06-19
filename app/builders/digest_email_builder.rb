class DigestEmailBuilder
  include EmailBuilderHelper
  def initialize(subscriber:, digest_run:, subscription_content_change_results:)
    @subscriber = subscriber
    @digest_run = digest_run
    @results = subscription_content_change_results
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.create!(
      subject: subject,
      body: body,
      address: subscriber.address,
      subscriber_id: subscriber.id,
    )
  end

  private_class_method :new

private

  attr_reader :subscriber, :digest_run, :results

  def body
    presented_results.concat("\n\n&nbsp;\n\n---\n\n")
      .concat(permission_reminder).concat("\n")
      .concat(presented_manage_subscriptions_links).concat("\n\n&nbsp;\n\n")
      .concat(feedback_link)
  end

  def presented_results
    results.map { |result| presented_segment(result) }.join("\n&nbsp;\n\n")
  end

  def presented_segment(result)
    <<~RESULT
      ##{result.subscriber_list_title}&nbsp;

      #{deduplicate_and_present(result.content_changes)}
      ---

      #{unsubscribe_link(result)}
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
      ContentChangePresenter.call(content_change, frequency: frequency)
    end

    changes.join("\n---\n\n")
  end

  def unsubscribe_link(result)
    UnsubscribeLinkPresenter.call(
      id: result.subscription_id,
      title: result.subscriber_list_title
    )
  end

  def presented_manage_subscriptions_links
    ManageSubscriptionsLinkPresenter.call(address: subscriber.address)
  end
end

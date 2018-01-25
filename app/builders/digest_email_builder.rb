class DigestEmailBuilder
  def initialize(subscriber:, digest_run:, subscription_content_change_results:)
    @subscriber = subscriber
    @digest_run = digest_run
    @results = subscription_content_change_results
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.new(
      subject: subject,
      body: body,
      address: subscriber.address
    )
  end

  private_class_method :new

private

  attr_reader :subscriber, :digest_run, :results

  def body
    results.map { |result| presented_result(result) }.join("\n&nbsp;\n\n")
  end

  def presented_result(result)
    <<~RESULT
      ##{result.subscriber_list_title}

      #{deduplicate_and_present(result.content_changes)}
      ---

      #{unsubscribe_link(result)}
    RESULT
  end

  def subject
    if digest_run.daily?
      "GOV.UK Daily Update"
    else
      "GOV.UK Weekly Update"
    end
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
      ContentChangePresenter.call(content_change)
    end

    changes.join("\n---\n\n")
  end

  def unsubscribe_link(result)
    UnsubscribeLinkPresenter.call(
      uuid: result.subscription_uuid,
      title: result.subscriber_list_title
    )
  end
end
